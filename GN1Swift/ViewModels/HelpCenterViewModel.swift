import Foundation
import Combine
import FirebaseFirestore
import Network

final class HelpCenterViewModel: ObservableObject {

    // MARK: - Published State

    @Published var faqItems: [FAQItem] = []
    @Published var pendingTickets: [SupportTicket] = []
    @Published var ticketHistory: [SupportTicket] = []
    @Published var isOffline: Bool = false
    @Published var isLoading: Bool = false
    @Published var ticketTitle: String = ""
    @Published var ticketDescription: String = ""
    @Published var showTicketSuccess: Bool = false

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
    // MARK: - Eventual Connectivity (NWPathMonitor)
    // =========================================================================
    // Reconnect → sync pending tickets + reload help center
    // =========================================================================

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = path.status == .satisfied
            Task { @MainActor in
                if online && self.wasOffline {
                    self.isOffline = false
                    self.ticketService.syncPendingTickets()
                    self.loadHelpCenter()
                }
                self.wasOffline = !online
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // =========================================================================
    // MARK: - Load All — Simultaneous async let fetches
    // =========================================================================
    // Serves FAQ from cache immediately, then fires 3 concurrent Firebase fetches
    // =========================================================================

    func loadHelpCenter() {
        guard let userId = UserSession.shared.userId else { return }
        isLoading = true

        let isOnline = !wasOffline
        analytics.helpOpened(online: isOnline)

        // Show cached FAQ immediately if TTL still valid
        if let cached = faqCache.faqItems() {
            faqItems = cached
            analytics.faqLoadedFromCache(cacheHit: true)
        } else {
            analytics.faqLoadedFromCache(cacheHit: false)
        }
        pendingTickets = ticketService.loadPendingTickets()

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Three concurrent fetches — all start simultaneously
                async let faqFetch     = self.fetchFAQ()
                async let pendingFetch = self.fetchPendingLocal()
                async let historyFetch = self.fetchTicketHistory(userId: userId)

                // Await all results (they ran in parallel)
                let newFAQ     = try await faqFetch
                let newPending = try await pendingFetch
                let history    = try await historyFetch

                self.faqCache.setFAQItems(newFAQ)

                await MainActor.run {
                    self.faqItems       = newFAQ
                    self.pendingTickets = newPending
                    self.ticketHistory  = history
                    self.isOffline      = false
                    self.isLoading      = false
                    self.recordFAQUsage()
                }

            } catch {
                await MainActor.run {
                    // Partial failure: show whatever is available, never blank
                    if self.faqItems.isEmpty { self.faqItems = Self.defaultFAQ() }
                    self.isOffline = true
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Firestore Fetches

    private func fetchFAQ() async throws -> [FAQItem] {
        try await withCheckedThrowingContinuation { cont in
            db.collection("faq")
                .limit(to: 30)
                .getDocuments { snap, err in
                    if let err { cont.resume(throwing: err); return }
                    let items = snap?.documents.map { doc -> FAQItem in
                        let d = doc.data()
                        return FAQItem(
                            id:       doc.documentID,
                            question: d["question"] as? String ?? "",
                            answer:   d["answer"]   as? String ?? "",
                            category: d["category"] as? String ?? "General"
                        )
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

    // MARK: - Create Ticket (Offline-capable)

    func submitTicket() {
        let trimmed = ticketTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let ticket = ticketService.createTicket(title: trimmed, description: ticketDescription)
        pendingTickets.append(ticket)
        ticketTitle       = ""
        ticketDescription = ""
        showTicketSuccess = true

        analytics.ticketCreated(createdOffline: isOffline, online: !isOffline)
        if !isOffline { ticketService.syncPendingTickets() }
        recordTicketCreation()
    }

    // MARK: - Default FAQ (Shown when offline or Firestore empty)

    static func defaultFAQ() -> [FAQItem] {
        [
            FAQItem(id: "1", question: "How do I book a ride?",
                    answer: "Go to the Home tab and tap 'Find a Ride' to search for available rides.",
                    category: "Rides"),
            FAQItem(id: "2", question: "How do I become a driver?",
                    answer: "Register with your vehicle details in your profile settings under the Driver section.",
                    category: "Account"),
            FAQItem(id: "3", question: "How do I add funds to my wallet?",
                    answer: "Go to Profile → Wallet and select your preferred payment method.",
                    category: "Wallet"),
            FAQItem(id: "4", question: "What happens when I am offline?",
                    answer: "The app uses cached data. Your support tickets are saved locally and sync when you reconnect.",
                    category: "General"),
            FAQItem(id: "5", question: "How is my rating calculated?",
                    answer: "Your rating is the average score from all your completed rides as rated by other users.",
                    category: "Account"),
        ]
    }

    // MARK: - Value Proposition Metrics

    private func recordFAQUsage() {
        let d = UserDefaults.standard
        d.set(d.integer(forKey: "metric_faqOpenCount") + 1,
              forKey: "metric_faqOpenCount")
    }

    private func recordTicketCreation() {
        UserDefaults.standard.set(Date().timeIntervalSince1970,
                                  forKey: "metric_lastTicketCreatedAt")
    }
}
