import Foundation

struct UserAnalytics {
    let userId: String
    let favoriteZone: String
    let favoriteHour: Int
    let totalRides: Int

    init(from data: [String: Any]) {
        self.userId = data["userId"] as? String ?? ""
        self.favoriteZone = data["favoriteZone"] as? String ?? ""
        self.favoriteHour = data["favoriteHour"] as? Int ?? 0
        self.totalRides = data["totalRides"] as? Int ?? 0
    }
}
