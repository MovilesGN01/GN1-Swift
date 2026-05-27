import Foundation
import Combine
import FirebaseFirestore
import Network

// MARK: - Sync state for retry UI

enum TicketSyncState {
    case idle
    case syncing
    case success
    case failed(attempts: Int)
}

// MARK: - HelpCenterViewModel
//
// Multi-threading strategy: Task + async let  (concurrent FAQ + history + pending load)
// Cache strategy:           TTL Cache (FAQCacheService — NO NSCache, pure struct + timestamp, 30 min TTL)
// Local storage:            JSON queue file (pending_support.json via SupportTicketService)
// Eventual connectivity:    NWPathMonitor + manual retry with retryCount tracking

final class HelpCenterViewModel: ObservableObject {

    // MARK: - Published State

    @Published var faqItems:       [FAQItem]       = []
    @Published var pendingTickets: [SupportTicket] = []
    @Published var ticketHistory:  [SupportTicket] = []
    @Published var isOffline:  Bool   = false
    @Published var isLoading:  Bool   = false
    @Published var isRetrying: Bool   = false
    @Published var retryCount: Int    = 0
    @Published var syncState:  TicketSyncState = .idle
    @Published var ticketTitle:       String = ""
    @Published var ticketDescription: String = ""
    @Published var showTicketSuccess: Bool   = false

    var cacheExpiresIn: String {
        let mins = FAQCacheService.shared.minutesUntilExpiry
        return mins > 0 ? "FAQ cache: \(mins) min left" : "FAQ cache expired"
    }

    // MARK: - Services

    private let db            = Firestore.firestore()
    private let ticketService = SupportTicketService.shared
    private let faqCache      = FAQCacheService.shared
    private let analytics     = AnalyticsService.shared
    private let monitor       = NWPathMonitor()
    private var wasOffline    = false

    init() {
        pendingTickets = ticketService.loadPendingTickets()
        startNetworkMonitoring()
    }

    deinit { monitor.cancel() }

    // =========================================================================
    // MARK: - Eventual Connectivity — NWPathMonitor
    // On reconnect: sync pending ticket queue + reload help center.
    // =========================================================================

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let online = path.status == .satisfied
            Task { @MainActor in
                let wasDown    = self.wasOffline
                self.wasOffline = !online
                self.isOffline  = !online
                if online && wasDown {
                    self.syncState = .syncing
                    self.ticketService.syncPendingTickets { success in
                        self.pendingTickets = self.ticketService.loadPendingTickets()
                        self.syncState = success
                            ? .success
                            : .failed(attempts: self.retryCount)
                    }
                    self.loadHelpCenter()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // =========================================================================
    // MARK: - Load Help Center (public entry point)
    // Spins up a Task so callers (View .onAppear) don't need an async context.
    // Inside the Task, async let fires all fetches concurrently.
    // =========================================================================

    func loadHelpCenter() {
        Task { await performLoad() }
    }

    private func performLoad() async {
        guard let userId = UserSession.shared.userId else { return }

        await MainActor.run {
            isLoading = true
            let isOnline = !wasOffline
            analytics.helpOpened(online: isOnline)

            // Serve TTL-cached FAQ immediately while network loads
            if let cached = faqCache.faqItems() {
                faqItems = cached
                analytics.faqLoadedFromCache(cacheHit: true)
            } else {
                analytics.faqLoadedFromCache(cacheHit: false)
            }
            pendingTickets = ticketService.loadPendingTickets()
        }

        do {
            // async let starts all three fetches simultaneously — not sequential
            async let faqFetch     = fetchFAQ()
            async let historyFetch = fetchTicketHistory(userId: userId)
            async let pendingFetch = fetchPendingLocal()

            let (newFAQ, history, pending) = try await (faqFetch, historyFetch, pendingFetch)
            faqCache.setFAQItems(newFAQ)

            await MainActor.run {
                faqItems       = newFAQ
                ticketHistory  = history
                pendingTickets = pending
                isOffline      = false
                isLoading      = false
            }

        } catch {
            await MainActor.run {
                if faqItems.isEmpty { faqItems = Self.defaultFAQ() }
                isOffline = true
                isLoading = false
            }
        }
    }

    // =========================================================================
    // MARK: - Retry Sync (manual — triggered by user via Retry button)
    // retryCount tracks total attempts so UI can display "Attempted X times".
    // =========================================================================

    func retrySync() {
        guard !isRetrying else { return }
        isRetrying = true
        retryCount += 1
        syncState  = .syncing

        ticketService.syncPendingTickets { [weak self] success in
            guard let self else { return }
            self.isRetrying    = false
            self.pendingTickets = self.ticketService.loadPendingTickets()
            self.syncState = success
                ? .success
                : .failed(attempts: self.retryCount)
        }
    }

    // =========================================================================
    // MARK: - Create Ticket (offline-capable)
    // =========================================================================

    func submitTicket() {
        let trimmed = ticketTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let ticket = ticketService.createTicket(title: trimmed, description: ticketDescription)
        pendingTickets.append(ticket)
        ticketTitle       = ""
        ticketDescription = ""
        showTicketSuccess = true

        analytics.ticketCreated(createdOffline: isOffline, online: !isOffline)

        if !isOffline {
            syncState = .syncing
            ticketService.syncPendingTickets { [weak self] success in
                guard let self else { return }
                self.pendingTickets = self.ticketService.loadPendingTickets()
                self.syncState = success ? .success : .failed(attempts: self.retryCount)
            }
        }
    }

    // MARK: - Firestore Fetches

    private func fetchFAQ() async throws -> [FAQItem] {
        try await withCheckedThrowingContinuation { cont in
            db.collection("faq").limit(to: 30).getDocuments { snap, err in
                if let err { cont.resume(throwing: err); return }
                let items = snap?.documents.map { doc -> FAQItem in
                    let d = doc.data()
                    return FAQItem(id: doc.documentID,
                                   question: d["question"] as? String ?? "",
                                   answer:   d["answer"]   as? String ?? "",
                                   category: d["category"] as? String ?? "General")
                } ?? []
                cont.resume(returning: items.isEmpty ? Self.defaultFAQ() : items)
            }
        }
    }

    private func fetchPendingLocal() async throws -> [SupportTicket] {
        ticketService.loadPendingTickets()
    }

    private func fetchTicketHistory(userId: String) async throws -> [SupportTicket] {
        try await ticketService.fetchTicketHistory(userId: userId)
    }

    // MARK: - Default FAQ (offline / empty Firestore fallback)

    static func defaultFAQ() -> [FAQItem] {
        [
            FAQItem(id: "1", question: "How do I book a ride?",
                    answer: "Go to the Home tab and tap 'Find a Ride'.",
                    category: "Rides"),
            FAQItem(id: "2", question: "How do I become a driver?",
                    answer: "Register with your vehicle details in Profile → Driver section.",
                    category: "Account"),
            FAQItem(id: "3", question: "How do I add funds to my wallet?",
                    answer: "Go to Profile → Wallet, tap 'Add Funds', and choose an amount and payment method.",
                    category: "Wallet"),
            FAQItem(id: "4", question: "What happens when I am offline?",
                    answer: "The app uses a TTL cache for FAQ (30 min). Support tickets are saved in a local queue and sync automatically when you reconnect.",
                    category: "General"),
            FAQItem(id: "5", question: "How is my rating calculated?",
                    answer: "Your rating is the average score from all completed rides.",
                    category: "Account"),
        ]
    }
}
