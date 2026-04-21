import SwiftUI

extension Ride {
    var urgencyLabel: String {
        let minutesUntilDeparture = departureTime.timeIntervalSinceNow / 60
        let leavingSoon = minutesUntilDeparture > 0 && minutesUntilDeparture <= 30

        if leavingSoon && seatsAvailable <= 2 { return "Leaving Soon" }
        if seatsAvailable <= 1 { return "Almost Full" }
        if seatsAvailable == 2 { return "Filling Fast" }
        return "Available"
    }

    var urgencyColor: Color {
        switch urgencyLabel {
        case "Almost Full", "Leaving Soon": return .red
        case "Filling Fast": return .orange
        default: return .green
        }
    }
}
