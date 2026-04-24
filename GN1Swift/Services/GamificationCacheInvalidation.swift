import Foundation
import CryptoKit

struct GamificationCacheMetadata: Codable {
    let profileHash: String?
    let leaderboardHash: String?
    let profileTimestamp: Double
    let leaderboardTimestamp: Double
    let version: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case profileHash, leaderboardHash, profileTimestamp, leaderboardTimestamp, version
    }
}

class GamificationCacheInvalidation {
    static let shared = GamificationCacheInvalidation()
    
    private let defaults = UserDefaults.standard
    private let metadataKey = "gamificationCacheMetadata"
    private let cacheDurationSeconds: TimeInterval = 3600  // 1 hora
    
    // MARK: - Hash Calculation
    
    func calculateHash<T: Encodable>(_ object: T) -> String {
        do {
            let data = try JSONEncoder().encode(object)
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            print("Error calculating hash: \(error)")
            return ""
        }
    }
    
    // MARK: - Metadata Management
    
    func saveProfileMetadata(_ profile: UserGamification) {
        let hash = calculateHash(profile)
        var metadata = loadMetadata() ?? GamificationCacheMetadata(
            profileHash: nil,
            leaderboardHash: nil,
            profileTimestamp: Date().timeIntervalSince1970,
            leaderboardTimestamp: 0
        )
        
        metadata = GamificationCacheMetadata(
            profileHash: hash,
            leaderboardHash: metadata.leaderboardHash,
            profileTimestamp: Date().timeIntervalSince1970,
            leaderboardTimestamp: metadata.leaderboardTimestamp,
            version: metadata.version
        )
        
        persistMetadata(metadata)
    }
    
    func saveLeaderboardMetadata(_ leaderboard: [UserGamification]) {
        let hash = calculateHash(leaderboard)
        var metadata = loadMetadata() ?? GamificationCacheMetadata(
            profileHash: nil,
            leaderboardHash: nil,
            profileTimestamp: 0,
            leaderboardTimestamp: Date().timeIntervalSince1970
        )
        
        metadata = GamificationCacheMetadata(
            profileHash: metadata.profileHash,
            leaderboardHash: hash,
            profileTimestamp: metadata.profileTimestamp,
            leaderboardTimestamp: Date().timeIntervalSince1970,
            version: metadata.version
        )
        
        persistMetadata(metadata)
    }
    
    // MARK: - Cache Validation
    
    func isProfileCacheValid() -> Bool {
        guard let metadata = loadMetadata() else { return false }
        let elapsed = Date().timeIntervalSince1970 - metadata.profileTimestamp
        return elapsed < cacheDurationSeconds
    }
    
    func isLeaderboardCacheValid() -> Bool {
        guard let metadata = loadMetadata() else { return false }
        let elapsed = Date().timeIntervalSince1970 - metadata.leaderboardTimestamp
        return elapsed < cacheDurationSeconds
    }
    
    func hasProfileChanged(_ newProfile: UserGamification) -> Bool {
        guard let metadata = loadMetadata() else { return true }
        let newHash = calculateHash(newProfile)
        return newHash != metadata.profileHash
    }
    
    func hasLeaderboardChanged(_ newLeaderboard: [UserGamification]) -> Bool {
        guard let metadata = loadMetadata() else { return true }
        let newHash = calculateHash(newLeaderboard)
        return newHash != metadata.leaderboardHash
    }
    
    // MARK: - Private Helpers
    
    private func loadMetadata() -> GamificationCacheMetadata? {
        guard let data = defaults.data(forKey: metadataKey) else { return nil }
        do {
            return try JSONDecoder().decode(GamificationCacheMetadata.self, from: data)
        } catch {
            print("Error decoding metadata: \(error)")
            return nil
        }
    }
    
    private func persistMetadata(_ metadata: GamificationCacheMetadata) {
        do {
            let encoded = try JSONEncoder().encode(metadata)
            defaults.set(encoded, forKey: metadataKey)
        } catch {
            print("Error encoding metadata: \(error)")
        }
    }
    
    func clearMetadata() {
        defaults.removeObject(forKey: metadataKey)
    }
}
