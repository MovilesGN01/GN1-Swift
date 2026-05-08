import Foundation
import FirebaseFirestore

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

    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? ""
        self.name = dict["name"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.icon = dict["icon"] as? String ?? "star.fill"
        self.color = dict["color"] as? String ?? "blue"
        self.progress = dict["progress"] as? Int
        self.unlockedAt = UserGamification.parseDate(dict["unlockedAt"])
    }

    init(
        id: String,
        name: String,
        description: String,
        icon: String,
        color: String,
        unlockedAt: Date? = nil,
        progress: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.unlockedAt = unlockedAt
        self.progress = progress
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
    var displayName: String = ""
    var points: Int = 0
    var level: Int = 1
    var totalXP: Int = 0
    var badges: [Badge] = []
    var streakInfo: StreakInfo = StreakInfo()
    var lastGamificationUpdate: Date = Date()

    enum CodingKeys: String, CodingKey {
        case userId, displayName, points, level, totalXP, badges
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

    init(
        userId: String,
        displayName: String = "",
        points: Int = 0,
        level: Int = 1,
        totalXP: Int = 0,
        badges: [Badge] = [],
        streakInfo: StreakInfo = StreakInfo(),
        lastGamificationUpdate: Date = Date()
    ) {
        self.userId = userId
        self.displayName = displayName
        self.points = points
        self.level = level
        self.totalXP = totalXP
        self.badges = badges
        self.streakInfo = streakInfo
        self.lastGamificationUpdate = lastGamificationUpdate
    }

    static func parseDate(_ raw: Any?) -> Date? {
        guard let raw else { return nil }

        if let date = raw as? Date { return date }
        if let ts = raw as? Timestamp { return ts.dateValue() }
        if let seconds = raw as? TimeInterval { return Date(timeIntervalSince1970: seconds) }
        if let intSeconds = raw as? Int { return Date(timeIntervalSince1970: TimeInterval(intSeconds)) }

        if let map = raw as? [String: Any] {
            if let seconds = map["_seconds"] as? TimeInterval {
                return Date(timeIntervalSince1970: seconds)
            }
            if let seconds = map["seconds"] as? TimeInterval {
                return Date(timeIntervalSince1970: seconds)
            }
        }

        return nil
    }
    
    init(from dict: [String: Any]) {
        self.userId = dict["userId"] as? String ?? dict["userID"] as? String ?? ""
        self.displayName = dict["displayName"] as? String ?? ""
        self.points = dict["points"] as? Int ?? 0
        self.level = dict["level"] as? Int ?? 1
        self.totalXP = dict["totalXP"] as? Int ?? 0
        self.lastGamificationUpdate = Self.parseDate(dict["lastGamificationUpdate"]) ?? Date()
        
        // Parse badges
        if let badgesData = dict["badges"] as? [[String: Any]] {
            self.badges = badgesData.map { Badge(from: $0) }
        } else {
            self.badges = []
        }
        
        // Parse streak info
        if let streakData = dict["streakInfo"] as? [String: Any] {
            self.streakInfo = StreakInfo(
                currentStreak: streakData["currentStreak"] as? Int ?? 0,
                longestStreak: streakData["longestStreak"] as? Int ?? 0,
                lastActivityDate: Self.parseDate(streakData["lastActivityDate"])
            )
        } else {
            self.streakInfo = StreakInfo()
        }
    }
}
