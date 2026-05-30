import Foundation

// MARK: - NSCache layer for wallet data
//
// Decision: NSCache chosen because the OS can evict entries under memory pressure
// without crashing — unlike a plain Dictionary.
//
// Limits:
//   transactions: countLimit 50  (keeps last 50 user entries per key)
//   cards:        countLimit 20
//   TTL:          5 minutes — balance-critical data must stay fresh.
//
// Cache flow:  NSCache → UserDefaults / JSON → Firestore

final class WalletCacheService {
    static let shared = WalletCacheService()
    private init() {
        txnCache.countLimit  = 50
        cardCache.countLimit = 20
    }

    private let txnCache  = NSCache<NSString, NSArray>()
    private let cardCache = NSCache<NSString, NSArray>()
    private var balanceMap:  [String: Double] = [:]
    private var timestamps:  [String: Date]   = [:]
    private let ttl: TimeInterval = 300 // 5 minutes

    // MARK: - TTL helpers

    private func isValid(key: String) -> Bool {
        guard let ts = timestamps[key] else { return false }
        return Date().timeIntervalSince(ts) < ttl
    }

    private func evict(key: String) {
        txnCache.removeObject(forKey:  (key + "_t") as NSString)
        cardCache.removeObject(forKey: (key + "_c") as NSString)
        balanceMap.removeValue(forKey: key)
        timestamps.removeValue(forKey: key)
    }

    func invalidateAll(forKey key: String) { evict(key: key) }

    // MARK: - Balance

    func balance(forKey key: String) -> Double? {
        guard isValid(key: key) else { evict(key: key); return nil }
        return balanceMap[key]
    }

    func setBalance(_ value: Double, forKey key: String) {
        balanceMap[key]  = value
        timestamps[key]  = Date()
    }

    // MARK: - Transactions

    func transactions(forKey key: String) -> [WalletTransaction]? {
        guard isValid(key: key),
              let arr = txnCache.object(forKey: (key + "_t") as NSString) else { return nil }
        return arr.compactMap { $0 as? NSDictionary }.map { d in
            WalletTransaction(
                id:            d["id"]            as? String ?? UUID().uuidString,
                amount:        d["amount"]        as? Double ?? 0,
                description:   d["description"]   as? String ?? "",
                date:          d["date"]          as? Double ?? 0,
                type:          d["type"]          as? String ?? "debit",
                paymentMethod: d["paymentMethod"] as? String ?? "Cash",
                status:        d["status"]        as? String ?? "completed",
                syncPending:   d["syncPending"]   as? Bool   ?? false
            )
        }
    }

    func setTransactions(_ txns: [WalletTransaction], forKey key: String) {
        let arr = txns.map { t -> NSDictionary in
            ["id": t.id, "amount": t.amount, "description": t.description,
             "date": t.date, "type": t.type, "paymentMethod": t.paymentMethod,
             "status": t.status, "syncPending": t.syncPending]
        } as NSArray
        txnCache.setObject(arr, forKey: (key + "_t") as NSString)
        timestamps[key] = Date()
    }

    // MARK: - Cards

    func cards(forKey key: String) -> [SavedCard]? {
        guard isValid(key: key),
              let arr = cardCache.object(forKey: (key + "_c") as NSString) else { return nil }
        return arr.compactMap { $0 as? NSDictionary }.map { d in
            SavedCard(
                id:           d["id"]           as? String ?? UUID().uuidString,
                holderName:   d["holderName"]   as? String ?? "",
                maskedNumber: d["maskedNumber"] as? String ?? "",
                expiration:   d["expiration"]   as? String ?? "",
                type:         d["type"]         as? String ?? "Credit Card"
            )
        }
    }

    func setCards(_ cards: [SavedCard], forKey key: String) {
        let arr = cards.map { c -> NSDictionary in
            ["id": c.id, "holderName": c.holderName,
             "maskedNumber": c.maskedNumber, "expiration": c.expiration, "type": c.type]
        } as NSArray
        cardCache.setObject(arr, forKey: (key + "_c") as NSString)
        timestamps[key] = Date()
    }
}
