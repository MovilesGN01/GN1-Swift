import Foundation

class CachedGamificationObject: NSObject {
    let profile: UserGamification
    let timestamp: Date
    
    init(profile: UserGamification) {
        self.profile = profile
        self.timestamp = Date()
    }
}

class GamificationMemoryCache {
    static let shared = GamificationMemoryCache()
    
    private let cache = NSCache<NSString, CachedGamificationObject>()
    private let leaderboardCache = NSCache<NSString, NSArray>()
    
    init() {
        // Configurar límites de NSCache (LRU automático)
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB máximo
        cache.countLimit = 100  // Máximo 100 objetos
        
        leaderboardCache.totalCostLimit = 20 * 1024 * 1024  // 20MB para leaderboard
        leaderboardCache.countLimit = 10  // Máximo 10 leaderboards cacheados
    }
    
    // MARK: - Profile Cache
    
    func setProfile(_ profile: UserGamification, forKey key: String) {
        let cached = CachedGamificationObject(profile: profile)
        let cost = MemoryLayout<UserGamification>.size
        cache.setObject(cached, forKey: key as NSString, cost: cost)
    }
    
    func getProfile(forKey key: String) -> UserGamification? {
        return cache.object(forKey: key as NSString)?.profile
    }
    
    func removeProfile(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - Leaderboard Cache
    
    func setLeaderboard(_ players: [UserGamification], forKey key: String = "leaderboard") {
        let nsArray = players as NSArray
        let cost = MemoryLayout<UserGamification>.size * players.count
        leaderboardCache.setObject(nsArray, forKey: key as NSString, cost: cost)
    }
    
    func getLeaderboard(forKey key: String = "leaderboard") -> [UserGamification]? {
        guard let nsArray = leaderboardCache.object(forKey: key as NSString) as? [UserGamification] else {
            return nil
        }
        return nsArray
    }
    
    func removeLeaderboard(forKey key: String = "leaderboard") {
        leaderboardCache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - Badges Individual Cache
    
    func setBadges(_ badges: [Badge], forKey userId: String) {
        let key = "badges_\(userId)" as NSString
        let nsArray = badges as NSArray
        leaderboardCache.setObject(nsArray, forKey: key, cost: MemoryLayout<Badge>.size * badges.count)
    }
    
    func getBadges(forKey userId: String) -> [Badge]? {
        let key = "badges_\(userId)" as NSString
        guard let nsArray = leaderboardCache.object(forKey: key) as? [Badge] else {
            return nil
        }
        return nsArray
    }
    
    // MARK: - Cache Management
    
    func clearAll() {
        cache.removeAllObjects()
        leaderboardCache.removeAllObjects()
    }
    
    func getMemoryUsage() -> (profiles: Int, leaderboards: Int) {
        return (cache.countLimit, leaderboardCache.countLimit)
    }
}
