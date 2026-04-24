import Foundation

class GamificationCacheManager {
    static let shared = GamificationCacheManager()
    
    private let defaults = UserDefaults.standard
    private let profileKey = "cachedGamificationProfile"
    private let leaderboardKey = "cachedLeaderboard"
    private let cacheTimestampKey = "gamificationCacheTimestamp"
    private let cacheDurationSeconds: TimeInterval = 3600 // 1 hour
    
    // MARK: - Profile Caching
    
    func saveProfile(_ profile: UserGamification) {
        do {
            let encoded = try JSONEncoder().encode(profile)
            defaults.set(encoded, forKey: profileKey)
            defaults.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            print("Error caching profile: \(error.localizedDescription)")
        }
    }
    
    func loadCachedProfile() -> UserGamification? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        do {
            let profile = try JSONDecoder().decode(UserGamification.self, from: data)
            return profile
        } catch {
            print("Error decoding cached profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    func isCacheValid() -> Bool {
        guard let timestamp = defaults.value(forKey: cacheTimestampKey) as? TimeInterval else {
            return false
        }
        let elapsed = Date().timeIntervalSince1970 - timestamp
        return elapsed < cacheDurationSeconds
    }
    
    func clearProfileCache() {
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: cacheTimestampKey)
    }
    
    // MARK: - Leaderboard Caching
    
    func saveLeaderboard(_ players: [UserGamification]) {
        do {
            let encoded = try JSONEncoder().encode(players)
            defaults.set(encoded, forKey: leaderboardKey)
        } catch {
            print("Error caching leaderboard: \(error.localizedDescription)")
        }
    }
    
    func loadCachedLeaderboard() -> [UserGamification]? {
        guard let data = defaults.data(forKey: leaderboardKey) else { return nil }
        do {
            let leaderboard = try JSONDecoder().decode([UserGamification].self, from: data)
            return leaderboard
        } catch {
            print("Error decoding cached leaderboard: \(error.localizedDescription)")
            return nil
        }
    }
    
    func clearLeaderboardCache() {
        defaults.removeObject(forKey: leaderboardKey)
    }
    
    // MARK: - Clear All
    
    func clearAllCaches() {
        clearProfileCache()
        clearLeaderboardCache()
    }
}
