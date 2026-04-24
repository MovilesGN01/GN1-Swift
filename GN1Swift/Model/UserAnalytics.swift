import Foundation

struct UserAnalytics {
    let userId: String
    let favoriteZone: String
    let favoriteHour: Int
    let totalRides: Int
    
    // Gamification fields
    let points: Int
    let level: Int
    let badges: [String]
    let streakDays: Int

    init(from data: [String: Any]) {
        self.userId = data["userId"] as? String ?? ""
        self.favoriteZone = data["favoriteZone"] as? String ?? ""
        self.favoriteHour = data["favoriteHour"] as? Int ?? 0
        self.totalRides = data["totalRides"] as? Int ?? 0
        
        // Gamification
        self.points = data["points"] as? Int ?? 0
        self.level = data["level"] as? Int ?? 1
        self.badges = data["badges"] as? [String] ?? []
        self.streakDays = data["streakDays"] as? Int ?? 0
    }
}
