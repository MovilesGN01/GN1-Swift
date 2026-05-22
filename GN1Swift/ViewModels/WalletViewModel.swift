import Foundation
import FirebaseFirestore
import Network

final class WalletViewModel: ObservableObject {

    // MARK: - Published State

    @Published var balance: Double = 0.0
    @Published var transactions: [WalletTransaction] = []
    @Published var preferredPaymentMethod: String = "Credit Card"
    @Published var isOffline: Bool = false
    @Published var isLoading: Bool = false
    @Published var dataSource: String = ""

    // Micro-optimization metrics (before/after cache)
    @Published var cacheLoadTime: Double = 0.0
    @Published var networkLoadTime: Double = 0.0

    // MARK: - Services

    private let db            = Firestore.firestore()
    private let cache         = WalletCacheService.shared
    private let localStorage  = WalletLocalStorageService.shared
    private let monitor       = NWPathMonitor()
    private var wasOffline    = false

    init() {
        preferredPaymentMethod = localStorage.preferredPaymentMethod
        startNetworkMonitoring()
    }

    deinit { monitor.cancel() }

    // =========================================================================
    // MARK: - Eventual Connectivity (NWPathMonitor)
    // =========================================================================
    // Scenario: internet restored → auto sync wallet
    // =========================================================================

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = path.status == .satisfied
            Task { @MainActor in
                if online && self.wasOffline {
                    self.isOffline = false
                    self.loadWallet()   // auto-sync on reconnect
                }
                self.wasOffline = !online
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // =========================================================================
    // MARK: - Load Wallet — Cache-First Strategy
    // =========================================================================
    // 1. Check NSCache (fastest — in-memory)
    // 2. Check JSON snapshot (offline fallback)
    // 3. Always refresh from Firebase in background
    // =========================================================================

    func loadWallet() {
        guard let userId = UserSession.shared.userId else { return }
        isLoading = true

        let cacheStart = Date()

        // Layer 1: NSCache hit → show immediately, refresh in background
        if let cached = cache.transactions(forKey: userId) {
            cacheLoadTime = Date().timeIntervalSince(cacheStart) * 1000
            let txns = cached.compactMap { $0 as? NSDictionary }.map { d in
                WalletTransaction(
                    id:          d["id"]          as? String ?? UUID().uuidString,
                    amount:      d["amount"]      as? Double ?? 0,
                    description: d["description"] as? String ?? "",
                    date:        d["date"]        as? Double ?? 0,
                    type:        d["type"]        as? String ?? "debit"
                )
            }
            transactions = Array(txns.prefix(10))
            dataSource   = "NSCache (in-memory)"
            isLoading    = false
            Task { [weak self] in await self?.refreshFromFirebase(userId: userId) }
            return
        }

        // Layer 2: JSON snapshot → show while network loads
        if let snapshot = localStorage.loadWalletSnapshot() {
            cacheLoadTime = Date().timeIntervalSince(cacheStart) * 1000
            balance       = snapshot.balance
            transactions  = Array(snapshot.transactions.prefix(10))
            dataSource    = "Local Snapshot (JSON)"
            isLoading     = false
        }

        // Always fire Firebase refresh
        Task { [weak self] in await self?.refreshFromFirebase(userId: userId) }
    }

    // =========================================================================
    // MARK: - Firebase Refresh — Concurrent async let
    // =========================================================================
    // async let fires both requests simultaneously (never blocks UI)
    // MainActor.run updates UI on the main thread
    // =========================================================================

    private func refreshFromFirebase(userId: String) async {
        let networkStart = Date()

        do {
            // Fire both requests at the same time — not sequential
            async let balanceFetch     = fetchBalance(userId: userId)
            async let transactionFetch = fetchTransactions(userId: userId)

            // Await both results (they ran in parallel)
            let newBalance = try await balanceFetch
            let newTxns    = try await transactionFetch

            let networkMs = Date().timeIntervalSince(networkStart) * 1000

            // Update NSCache with fresh data
            let arr = newTxns.map { t -> NSDictionary in
                ["id": t.id, "amount": t.amount,
                 "description": t.description, "date": t.date, "type": t.type]
            } as NSArray
            cache.setTransactions(arr, forKey: userId)

            // Update JSON snapshot for offline use
            localStorage.saveWalletSnapshot(
                WalletSnapshot(balance: newBalance, transactions: newTxns,
                               lastUpdate: Date().timeIntervalSince1970)
            )

            // UI update must run on main thread
            await MainActor.run {
                self.balance         = newBalance
                self.transactions    = Array(newTxns.prefix(10))
                self.isOffline       = false
                self.isLoading       = false
                self.networkLoadTime = networkMs
                self.dataSource      = "Firebase Firestore"
                self.recordUsage(offline: false)
            }

        } catch {
            let networkMs = Date().timeIntervalSince(networkStart) * 1000
            await MainActor.run {
                self.isOffline       = true
                self.isLoading       = false
                self.networkLoadTime = networkMs
                self.recordUsage(offline: true)
            }
        }
    }

    // MARK: - Firestore Fetches

    private func fetchBalance(userId: String) async throws -> Double {
        try await withCheckedThrowingContinuation { cont in
            db.collection("wallets").document(userId).getDocument { snap, err in
                if let err { cont.resume(throwing: err); return }
                cont.resume(returning: snap?.data()?["balance"] as? Double ?? 0.0)
            }
        }
    }

    private func fetchTransactions(userId: String) async throws -> [WalletTransaction] {
        try await withCheckedThrowingContinuation { cont in
            db.collection("wallets").document(userId)
                .collection("transactions")
                .order(by: "date", descending: true)
                .limit(to: 10)
                .getDocuments { snap, err in
                    if let err { cont.resume(throwing: err); return }
                    let txns = snap?.documents.map { doc -> WalletTransaction in
                        let d = doc.data()
                        return WalletTransaction(
                            id:          doc.documentID,
                            amount:      d["amount"]      as? Double ?? 0,
                            description: d["description"] as? String ?? "",
                            date: (d["date"] as? Timestamp)?.dateValue()
                                        .timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                            type:        d["type"]        as? String ?? "debit"
                        )
                    } ?? []
                    cont.resume(returning: txns)
                }
        }
    }

    // MARK: - Preferred Payment Method

    func updatePreferredPaymentMethod(_ method: String) {
        preferredPaymentMethod = method
        localStorage.preferredPaymentMethod = method
    }

    // MARK: - Value Proposition Metrics

    private func recordUsage(offline: Bool) {
        let d = UserDefaults.standard
        d.set(d.integer(forKey: "metric_walletOpenCount") + 1,
              forKey: "metric_walletOpenCount")
        if offline {
            d.set(d.integer(forKey: "metric_offlineWalletOpenCount") + 1,
                  forKey: "metric_offlineWalletOpenCount")
        }
    }
}
