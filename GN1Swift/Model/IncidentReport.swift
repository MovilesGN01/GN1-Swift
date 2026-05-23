import Foundation

enum ReportCategory: String, CaseIterable, Identifiable {
    case behavior   = "behavior"
    case harassment = "harassment"
    case fakeInfo   = "fake_info"
    case vehicle    = "vehicle"
    case other      = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .behavior:   return "Inappropriate behavior"
        case .harassment: return "Harassment"
        case .fakeInfo:   return "False information"
        case .vehicle:    return "Poor vehicle condition"
        case .other:      return "Other"
        }
    }

    var icon: String {
        switch self {
        case .behavior:   return "hand.raised.slash"
        case .harassment: return "exclamationmark.bubble"
        case .fakeInfo:   return "doc.badge.ellipsis"
        case .vehicle:    return "car.fill"
        case .other:      return "ellipsis.circle"
        }
    }
}

struct IncidentReport {
    let reportedUserId: String
    let reportedUserName: String
    let category: ReportCategory
    let description: String
}

enum ReportSource {
    case leaderboard
    case rideDetail
}
