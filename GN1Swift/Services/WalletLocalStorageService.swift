import Foundation

// MARK: - Models

struct WalletTransaction: Codable, Identifiable {
    var id: String
    var amount: Double
    var description: String
    var date: Double        // timeIntervalSince1970
    var type: String        // "credit" or "debit"
}

struct WalletSnapshot: Codable {
    var balance: Double
    var transactions: [WalletTransaction]
    var lastUpdate: Double  // timeIntervalSince1970
}

// MARK: - Service

// UserDefaults: preferredPaymentMethod
// JSON file: wallet_snapshot.json (balance, transactions, lastUpdate)
final class WalletLocalStorageService {
    static let shared = WalletLocalStorageService()

    private let defaults = UserDefaults.standard
    private let keyPreferredPayment = "wallet_preferredPaymentMethod"

    private var snapshotURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("wallet_snapshot.json")
    }

    // MARK: - UserDefaults: Preferred Payment Method

    var preferredPaymentMethod: String {
        get { defaults.string(forKey: keyPreferredPayment) ?? "Credit Card" }
        set { defaults.set(newValue, forKey: keyPreferredPayment) }
    }

    // MARK: - JSON Snapshot

    func saveWalletSnapshot(_ snapshot: WalletSnapshot) {
        guard let url = snapshotURL,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadWalletSnapshot() -> WalletSnapshot? {
        guard let url = snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WalletSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}
