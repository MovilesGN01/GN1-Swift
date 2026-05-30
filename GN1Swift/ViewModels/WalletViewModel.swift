import Foundation
import Combine
import FirebaseFirestore
import Network

// MARK: - WalletViewModel
//
// Multi-threading strategy: DispatchQueue.global (Firestore I/O) + DispatchQueue.main (UI)
// Cache strategy:           NSCache → UserDefaults/JSON → Firestore  (3 layers)
// Local storage:            UserDefaults (balance, method) + JSON files (cards, txns, pending queue)
// Eventual connectivity:    NWPathMonitor detects reconnect → auto-sync pending queue

final class WalletViewModel: ObservableObject {

    // MARK: - Published State

    @Published var balance: Double = 0.0
    @Published var transactions: [WalletTransaction] = []
    @Published var cards: [SavedCard] = []
    @Published var preferredPaymentMethod: String = "Cash"
    @Published var isOffline: Bool = false
    @Published var isLoading: Bool = false
    @Published var dataSource: String = ""
    @Published var pendingSyncCount: Int = 0
    @Published var cacheLoadTime: Double = 0.0
    @Published var networkLoadTime: Double = 0.0

    // MARK: - Services

    private let db           = Firestore.firestore()
    private let cache        = WalletCacheService.shared
    private let localStorage = WalletLocalStorageService.shared
    private let analytics    = AnalyticsService.shared
    private let monitor      = NWPathMonitor()
    private var wasOffline   = false

    init() {
        preferredPaymentMethod = localStorage.preferredPaymentMethod
        pendingSyncCount       = localStorage.loadPendingTransactions().count
        startNetworkMonitoring()
    }

    deinit { monitor.cancel() }

    // =========================================================================
    // MARK: - Eventual Connectivity — NWPathMonitor
    // Runs on background thread. When internet is restored after an offline
    // period, automatically reloads wallet and drains the pending sync queue.
    // =========================================================================

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let online = path.status == .satisfied
            DispatchQueue.main.async {
                let wasDown = self.wasOffline
                self.wasOffline = !online
                self.isOffline  = !online
                if online && wasDown {
                    self.loadWallet()
                    self.syncPendingTransactions()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // =========================================================================
    // MARK: - Load Wallet — 3-Layer Cache Strategy
    //
    // Layer 1: NSCache      — in-memory, sub-millisecond, lost on app kill
    // Layer 2: UserDefaults / JSON — persists across restarts
    // Layer 3: Firestore    — source of truth, refreshed in background
    // =========================================================================

    func loadWallet() {
        guard let userId = UserSession.shared.userId else { return }
        isLoading = true

        let isOnline  = !wasOffline
        let cacheStart = Date()
        analytics.walletOpened(userId: userId, online: isOnline)

        // Layer 1: NSCache hit — show immediately, still refresh from Firebase
        if let cachedBalance = cache.balance(forKey: userId) {
            cacheLoadTime = Date().timeIntervalSince(cacheStart) * 1000
            DispatchQueue.main.async {
                self.balance      = cachedBalance
                self.transactions = self.cache.transactions(forKey: userId) ?? []
                self.cards        = self.cache.cards(forKey: userId) ?? self.localStorage.loadCards()
                self.dataSource   = "NSCache (in-memory)"
                self.isLoading    = false
            }
            analytics.walletLoadedFromCache(cacheHit: true, loadTime: cacheLoadTime)
            analytics.walletTransactionViewed(online: isOnline)
            DispatchQueue.global(qos: .userInitiated).async { self.refreshFromFirebase(userId: userId) }
            return
        }

        // Layer 2: UserDefaults + JSON snapshot
        let localBalance = localStorage.balance
        let localCards   = localStorage.loadCards()
        let localTxns    = localStorage.loadWalletSnapshot()?.transactions ?? []

        if localBalance > 0 || !localCards.isEmpty || !localTxns.isEmpty {
            cacheLoadTime = Date().timeIntervalSince(cacheStart) * 1000
            DispatchQueue.main.async {
                self.balance      = localBalance
                self.cards        = localCards
                self.transactions = localTxns
                self.dataSource   = "Local Storage (UserDefaults + JSON)"
                self.isLoading    = false
            }
            analytics.walletOfflineSnapshotLoaded(snapshotExists: true)
            analytics.walletLoadedFromCache(cacheHit: true, loadTime: cacheLoadTime)
            analytics.walletTransactionViewed(online: isOnline)
        } else {
            analytics.walletOfflineSnapshotLoaded(snapshotExists: false)
        }

        // Layer 3: Firebase (always refreshes in background even after local hit)
        DispatchQueue.global(qos: .userInitiated).async { self.refreshFromFirebase(userId: userId) }
    }

    // =========================================================================
    // MARK: - Firebase Refresh  (DispatchQueue approach)
    //
    // DispatchGroup fires 3 concurrent Firestore reads on a background thread.
    // group.notify(queue: .main) guarantees UI update is on the main thread.
    // =========================================================================

    private func refreshFromFirebase(userId: String) {
        let start = Date()
        let group = DispatchGroup()

        var newBalance: Double              = localStorage.balance
        var newTxns:    [WalletTransaction] = []
        var newCards:   [SavedCard]         = []

        // Concurrent read 1 — wallet document (balance)
        group.enter()
        db.collection("wallets").document(userId).getDocument { snap, _ in
            if let data = snap?.data() {
                newBalance = data["balance"] as? Double ?? self.localStorage.balance
            }
            group.leave()
        }

        // Concurrent read 2 — transactions subcollection
        group.enter()
        db.collection("wallets").document(userId)
            .collection("transactions")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snap, _ in
                newTxns = snap?.documents.compactMap { doc -> WalletTransaction? in
                    let d = doc.data()
                    return WalletTransaction(
                        id:            doc.documentID,
                        amount:        d["amount"]        as? Double ?? 0,
                        description:   d["description"]   as? String ?? "",
                        date:          (d["timestamp"] as? Timestamp)?.dateValue()
                                           .timeIntervalSince1970 ?? 0,
                        type:          d["type"]          as? String ?? "credit",
                        paymentMethod: d["paymentMethod"] as? String ?? "Cash",
                        status:        d["status"]        as? String ?? "completed",
                        syncPending:   d["syncPending"]   as? Bool   ?? false
                    )
                } ?? []
                group.leave()
            }

        // Concurrent read 3 — saved cards subcollection
        group.enter()
        db.collection("wallets").document(userId)
            .collection("cards")
            .getDocuments { snap, _ in
                newCards = snap?.documents.compactMap { doc -> SavedCard? in
                    let d = doc.data()
                    return SavedCard(
                        id:           doc.documentID,
                        holderName:   d["holderName"]   as? String ?? "",
                        maskedNumber: d["maskedNumber"] as? String ?? "",
                        expiration:   d["expiration"]   as? String ?? "",
                        type:         d["type"]         as? String ?? "Credit Card"
                    )
                } ?? []
                group.leave()
            }

        // All three reads done — update cache, local storage, and UI on main thread
        group.notify(queue: .main) {
            let ms = Date().timeIntervalSince(start) * 1000

            // Populate NSCache with fresh data
            self.cache.setBalance(newBalance, forKey: userId)
            self.cache.setTransactions(newTxns, forKey: userId)
            self.cache.setCards(newCards, forKey: userId)

            // Persist locally (survives cache eviction and app restarts)
            self.localStorage.balance = newBalance
            self.localStorage.saveCards(newCards)
            self.localStorage.saveWalletSnapshot(
                WalletSnapshot(balance: newBalance, transactions: newTxns,
                               lastUpdate: Date().timeIntervalSince1970)
            )

            // Update UI
            self.balance         = newBalance
            self.transactions    = newTxns
            self.cards           = newCards
            self.isOffline       = false
            self.isLoading       = false
            self.networkLoadTime = ms
            self.dataSource      = "Firebase Firestore"

            self.analytics.walletLoadedFromCache(cacheHit: false, loadTime: ms)
            self.analytics.walletTransactionViewed(online: true)

            self.syncPendingTransactions()
        }
    }

    // =========================================================================
    // MARK: - Add Funds
    //
    // Immediate optimistic UI update → persist locally → sync Firestore.
    // Offline: transaction queued in JSON file with syncPending = true.
    // Uses merge: true on wallet document so it auto-creates if missing.
    // =========================================================================

    func addFunds(amount: Double, paymentMethod: String) {
        guard let userId = UserSession.shared.userId else { return }

        let isOnline   = !wasOffline
        let newBalance = balance + amount
        let txn = WalletTransaction(
            id:            UUID().uuidString,
            amount:        amount,
            description:   "Wallet Top Up",
            date:          Date().timeIntervalSince1970,
            type:          "credit",
            paymentMethod: paymentMethod,
            status:        isOnline ? "completed" : "pending_sync",
            syncPending:   !isOnline
        )

        // Optimistic local update (instant UI response)
        balance = newBalance
        transactions.insert(txn, at: 0)
        preferredPaymentMethod = paymentMethod

        // Persist — UserDefaults
        localStorage.balance               = newBalance
        localStorage.preferredPaymentMethod = paymentMethod

        // Persist — JSON snapshot
        var snap = localStorage.loadWalletSnapshot() ??
            WalletSnapshot(balance: 0, transactions: [], lastUpdate: 0)
        snap.balance = newBalance
        snap.transactions.insert(txn, at: 0)
        localStorage.saveWalletSnapshot(snap)

        // Persist — NSCache
        cache.setBalance(newBalance, forKey: userId)
        cache.setTransactions(transactions, forKey: userId)

        if isOnline {
            DispatchQueue.global(qos: .userInitiated).async {
                self.writeTransactionToFirestore(txn: txn, userId: userId, newBalance: newBalance)
            }
        } else {
            var pending = localStorage.loadPendingTransactions()
            pending.append(txn)
            localStorage.savePendingTransactions(pending)
            DispatchQueue.main.async { self.pendingSyncCount = pending.count }
        }
    }

    private func writeTransactionToFirestore(txn: WalletTransaction,
                                              userId: String,
                                              newBalance: Double) {
        // merge: true creates the wallet document if it doesn't exist yet
        db.collection("wallets").document(userId).setData([
            "balance":        newBalance,
            "lastUsedMethod": txn.paymentMethod,
            "updatedAt":      Timestamp(date: Date())
        ], merge: true)

        db.collection("wallets").document(userId)
            .collection("transactions")
            .document(txn.id)
            .setData([
                "amount":        txn.amount,
                "description":   txn.description,
                "type":          txn.type,
                "paymentMethod": txn.paymentMethod,
                "status":        "completed",
                "syncPending":   false,
                "timestamp":     Timestamp(date: Date(timeIntervalSince1970: txn.date))
            ])
    }

    // =========================================================================
    // MARK: - Pending Sync  (eventual connectivity drain)
    // Runs on background queue. Fires all pending transactions concurrently
    // via DispatchGroup. On completion, removes synced entries from JSON queue.
    // =========================================================================

    func syncPendingTransactions() {
        guard let userId = UserSession.shared.userId, !wasOffline else { return }
        let pending = localStorage.loadPendingTransactions()
        guard !pending.isEmpty else { return }

        DispatchQueue.global(qos: .background).async {
            let group      = DispatchGroup()
            var syncedIds: [String] = []

            for txn in pending {
                group.enter()
                self.db.collection("wallets").document(userId).setData([
                    "balance":        self.localStorage.balance,
                    "lastUsedMethod": txn.paymentMethod,
                    "updatedAt":      Timestamp(date: Date())
                ], merge: true)

                self.db.collection("wallets").document(userId)
                    .collection("transactions")
                    .document(txn.id)
                    .setData([
                        "amount":        txn.amount,
                        "description":   txn.description,
                        "type":          txn.type,
                        "paymentMethod": txn.paymentMethod,
                        "status":        "completed",
                        "syncPending":   false,
                        "timestamp":     Timestamp(date: Date(timeIntervalSince1970: txn.date))
                    ]) { err in
                        if err == nil { syncedIds.append(txn.id) }
                        group.leave()
                    }
            }

            group.notify(queue: .main) {
                var remaining = self.localStorage.loadPendingTransactions()
                remaining.removeAll { syncedIds.contains($0.id) }
                self.localStorage.savePendingTransactions(remaining)
                self.pendingSyncCount = remaining.count

                // Mark synced transactions as completed in the UI list
                for id in syncedIds {
                    if let idx = self.transactions.firstIndex(where: { $0.id == id }) {
                        self.transactions[idx].syncPending = false
                        self.transactions[idx].status      = "completed"
                    }
                }
            }
        }
    }

    // =========================================================================
    // MARK: - Card Management
    // Saves masked card locally + Firestore. Raw card number never stored.
    // =========================================================================

    func addCard(holderName: String, cardNumber: String, expiration: String, type: String) {
        guard let userId = UserSession.shared.userId else { return }
        let digits = cardNumber.filter { $0.isNumber }
        let last4  = String(digits.suffix(4))
        let masked = "**** **** **** \(last4)"

        let card = SavedCard(id: UUID().uuidString, holderName: holderName,
                             maskedNumber: masked, expiration: expiration, type: type)

        cards.append(card)
        localStorage.saveCards(cards)
        cache.setCards(cards, forKey: userId)

        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("wallets").document(userId)
                .collection("cards").document(card.id)
                .setData(["holderName": card.holderName, "maskedNumber": card.maskedNumber,
                          "expiration": card.expiration,  "type": card.type])
        }
    }

    // MARK: - Preferred Payment Method

    func updatePreferredPaymentMethod(_ method: String) {
        preferredPaymentMethod             = method
        localStorage.preferredPaymentMethod = method
    }

    // =========================================================================
    // MARK: - Validation helpers (static — usable from the View)
    // =========================================================================

    static func validateCardNumber(_ raw: String) -> Bool {
        raw.filter { $0.isNumber }.count == 16
    }

    static func validateExpiration(_ raw: String) -> Bool {
        let parts = raw.split(separator: "/")
        guard parts.count == 2,
              let month = Int(parts[0]), let year = Int(parts[1]),
              month >= 1, month <= 12, year >= 0 else { return false }
        return true
    }

    static func validateCVV(_ raw: String) -> Bool {
        raw.filter { $0.isNumber }.count == 3
    }

    static func validateNequi(_ raw: String) -> Bool {
        // Colombian mobile: 10 digits starting with 3
        let digits = raw.filter { $0.isNumber }
        return digits.count == 10 && digits.hasPrefix("3")
    }
}
