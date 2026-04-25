import Foundation

final class CacheService {
    static let shared = CacheService()

    private let rideCache = NSCache<NSString, NSArray>()

    private init() {
        rideCache.countLimit = 100
        rideCache.totalCostLimit = 5 * 1024 * 1024  // 5 MB
    }

    func rides(forKey key: String) -> [Ride]? {
        rideCache.object(forKey: key as NSString) as? [Ride]
    }

    func setRides(_ rides: [Ride], forKey key: String) {
        rideCache.setObject(rides as NSArray, forKey: key as NSString)
    }

    func invalidate(forKey key: String) {
        rideCache.removeObject(forKey: key as NSString)
    }

    func invalidateAll() {
        rideCache.removeAllObjects()
    }
}
