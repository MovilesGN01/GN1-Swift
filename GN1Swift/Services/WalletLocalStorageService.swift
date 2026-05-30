import Foundation

// MARK: - Models

struct WalletTransaction: Codable, Identifiable {
    var id: String
    var amount: Double
    var description: String
    var date: Double            // timeIntervalSince1970
    var type: String            // "credit" | "debit"
    var paymentMethod: String
    var status: String          // "completed" | "pending_sync"
    var syncPending: Bool

    init(id: String = UUID().uuidString,
         amount: Double,
         description: String,
         date: Double = Date().timeIntervalSince1970,
         type: String,
         paymentMethod: String = "Cash",
         status: String = "completed",
         syncPending: Bool = false) {
        self.id            = id
        self.amount        = amount
        self.description   = description
        self.date          = date
        self.type          = type
        self.paymentMethod = paymentMethod
        self.status        = status
        self.syncPending   = syncPending
    }

    // Backward-compatible decode: old JSON files may not have new fields
    init(from decoder: Decoder) throws {
        let c          = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self, forKey: .id)
        amount         = try c.decode(Double.self,  forKey: .amount)
        description    = try c.decode(String.self, forKey: .description)
        date           = try c.decode(Double.self,  forKey: .date)
        type           = try c.decode(String.self, forKey: .type)
        paymentMethod  = (try? c.decode(String.self, forKey: .paymentMethod)) ?? "Cash"
        status         = (try? c.decode(String.self, forKey: .status))        ?? "completed"
        syncPending    = (try? c.decode(Bool.self,   forKey: .syncPending))   ?? false
    }
}

struct SavedCard: Codable, Identifiable {
    var id: String
    var holderName: String
    var maskedNumber: String    // "**** **** **** 1234"
    var expiration: String      // "MM/YY"
    var type: String            // "Credit Card" | "Debit Card"
}

struct WalletSnapshot: Codable {
    var balance: Double
    var transactions: [WalletTransaction]
    var lastUpdate: Double
}

// MARK: - Service
//
// Strategy 1 — UserDefaults  : balance (Double) + lastUsedMethod (String)
//              Fast scalar reads; survives app restarts; no serialisation overhead.
//
// Strategy 2 — JSON files    : transactions snapshot  → wallet_snapshot.json
//                              saved cards            → wallet_cards.json
//                              offline pending queue  → wallet_pending_txns.json
//              Used for complex objects that cannot be stored in UserDefaults.

final class WalletLocalStorageService {
    static let shared = WalletLocalStorageService()
    private init() {}

    private let defaults   = UserDefaults.standard
    private let keyBalance = "wallet_balance"
    private let keyMethod  = "wallet_lastUsedMethod"

    // MARK: UserDefaults — balance & preferred method

    var balance: Double {
        get { defaults.double(forKey: keyBalance) }
        set { defaults.set(newValue, forKey: keyBalance) }
    }

    var preferredPaymentMethod: String {
        get { defaults.string(forKey: keyMethod) ?? "Cash" }
        set { defaults.set(newValue, forKey: keyMethod) }
    }

    // MARK: JSON — transactions snapshot

    private var snapshotURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("wallet_snapshot.json")
    }

    func saveWalletSnapshot(_ snapshot: WalletSnapshot) {
        guard let url = snapshotURL,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadWalletSnapshot() -> WalletSnapshot? {
        guard let url  = snapshotURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WalletSnapshot.self, from: data)
    }

    // MARK: JSON — saved cards

    private var cardsURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("wallet_cards.json")
    }

    func saveCards(_ cards: [SavedCard]) {
        guard let url  = cardsURL,
              let data = try? JSONEncoder().encode(cards) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadCards() -> [SavedCard] {
        guard let url  = cardsURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SavedCard].self, from: data)) ?? []
    }

    // MARK: JSON — offline pending transaction queue

    private var pendingURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("wallet_pending_txns.json")
    }

    func savePendingTransactions(_ txns: [WalletTransaction]) {
        guard let url  = pendingURL,
              let data = try? JSONEncoder().encode(txns) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadPendingTransactions() -> [WalletTransaction] {
        guard let url  = pendingURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([WalletTransaction].self, from: data)) ?? []
    }
}
