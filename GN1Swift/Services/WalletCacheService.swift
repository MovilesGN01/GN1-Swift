import Foundation

// NSCache for wallet transactions — countLimit 20, TTL 5 minutes
final class WalletCacheService {
    static let shared = WalletCacheService()

    private let cache = NSCache<NSString, NSArray>()
    private var timestamps: [String: Date] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes

    private init() {
        cache.countLimit = 20
    }

    func transactions(forKey key: String) -> NSArray? {
        guard let ts = timestamps[key], Date().timeIntervalSince(ts) < ttl else {
            cache.removeObject(forKey: key as NSString)
            timestamps.removeValue(forKey: key)
            return nil
        }
        return cache.object(forKey: key as NSString)
    }

    func setTransactions(_ txns: NSArray, forKey key: String) {
        cache.setObject(txns, forKey: key as NSString)
        timestamps[key] = Date()
    }

    func invalidate(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        timestamps.removeValue(forKey: key)
    }
}
