import Foundation

final class ProfileCacheService {
    static let shared = ProfileCacheService()

    private let cache = NSCache<NSString, NSDictionary>()

    private init() {
        cache.countLimit = 10
        cache.totalCostLimit = 1 * 1024 * 1024
    }

    func profile(forKey key: String) -> NSDictionary? {
        cache.object(forKey: key as NSString)
    }

    func setProfile(_ profile: NSDictionary, forKey key: String) {
        cache.setObject(profile, forKey: key as NSString)
    }

    func removeProfile(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}
