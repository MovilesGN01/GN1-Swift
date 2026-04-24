import Foundation

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let unlockedAt: Date?
    let progress: Int? // For badges in progress (0-100)
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color, unlockedAt, progress
    }
}

struct StreakInfo: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case currentStreak
        case longestStreak
        case lastActivityDate
    }
}

struct UserGamification: Codable {
    let userId: String
    var points: Int = 0
    var level: Int = 1
    var totalXP: Int = 0
    var badges: [Badge] = []
    var streakInfo: StreakInfo = StreakInfo()
    var lastGamificationUpdate: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case userId, points, level, totalXP, badges
        case streakInfo, lastGamificationUpdate
    }
    
    var pointsUntilNextLevel: Int {
        let baseLevelXP = 500
        let nextLevelXP = baseLevelXP * level
        let currentLevelStartXP = baseLevelXP * (level - 1)
        return max(0, currentLevelStartXP + nextLevelXP - totalXP)
    }
    
    var progressToNextLevel: Double {
        let baseLevelXP = 500
        let nextLevelXP = baseLevelXP * level
        let currentLevelStartXP = baseLevelXP * (level - 1)
        let totalInLevel = nextLevelXP
        let currentInLevel = totalXP - currentLevelStartXP
        return min(1.0, max(0.0, Double(currentInLevel) / Double(totalInLevel)))
    }
    
    var unlockedBadgesCount: Int {
        badges.filter { $0.isUnlocked }.count
    }
    
    // MARK: - Parsing from Firestore/Cloud Functions
    
    init(from dict: [String: Any]) {
        self.userId = dict["userId"] as? String ?? ""
        self.points = dict["points"] as? Int ?? 0
        self.level = dict["level"] as? Int ?? 1
        self.totalXP = dict["totalXP"] as? Int ?? 0
        self.lastGamificationUpdate = (dict["lastGamificationUpdate"] as? Date) ?? Date()
        
        // Parse badges
        if let badgesData = dict["badges"] as? [[String: Any]] {
            self.badges = badgesData.compactMap { badgeDict in
                let decoder = JSONDecoder()
                if let jsonData = try? JSONSerialization.data(withJSONObject: badgeDict),
                   let badge = try? decoder.decode(Badge.self, from: jsonData) {
                    return badge
                }
                return nil
            }
        } else {
            self.badges = []
        }
        
        // Parse streak info
        if let streakData = dict["streakInfo"] as? [String: Any] {
            self.streakInfo = StreakInfo(
                currentStreak: streakData["currentStreak"] as? Int ?? 0,
                longestStreak: streakData["longestStreak"] as? Int ?? 0,
                lastActivityDate: streakData["lastActivityDate"] as? Date
            )
        } else {
            self.streakInfo = StreakInfo()
        }
    }
}
