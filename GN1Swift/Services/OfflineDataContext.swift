import Foundation

/// A snapshot of locally cached user data used by the offline chatbot
/// to generate real, personalized responses without network access.
struct OfflineDataContext {
    let availableRides: [Ride]
    let pendingRequests: [RideRequest]
    let rideHistory: [RideHistory]
    let userId: String

    var isEmpty: Bool {
        availableRides.isEmpty && pendingRequests.isEmpty && rideHistory.isEmpty
    }

    /// Loads all three collections from CoreData in parallel.
    static func load(userId: String) async -> OfflineDataContext {
        let source = RideLocalDataSource()
        async let rides    = source.fetchRides()
        async let requests = source.fetchPassengerRequests(for: userId)
        async let history  = source.fetchRideHistory(for: userId)
        return await OfflineDataContext(
            availableRides: rides,
            pendingRequests: requests,
            rideHistory: history,
            userId: userId
        )
    }
}

// MARK: - Response generation

extension OfflineDataContext {

    /// Formats the cached marketplace rides as a plain-text list.
    func ridesResponse() -> String {
        guard !availableRides.isEmpty else {
            return "I don't have any rides cached locally right now. " +
                   "Connect to the internet and open the Rides tab to load the latest available rides."
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM, h:mm a"
        let lines = availableRides.prefix(6).map { ride in
            let time = formatter.string(from: ride.departureTime)
            let price = String(format: "$%.0f", ride.price)
            let rating = String(format: "%.1f", ride.driverRating)
            return "\(ride.origin) to \(ride.destination) — \(time) " +
                   "| \(ride.seatsAvailable) seat(s) | \(price) | Driver rating \(rating)"
        }
        let header = "Here are the \(min(availableRides.count, 6)) cached rides I found:"
        return ([header] + lines).joined(separator: "\n")
    }

    /// Formats the user's active (pending/accepted) requests.
    func requestsResponse() -> String {
        guard !pendingRequests.isEmpty else {
            return "You have no active ride requests cached locally. " +
                   "Go to the Rides tab and request a ride — it will appear here once synced."
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let lines = pendingRequests.map { req in
            let badge = req.status == "accepted" ? "Accepted" : "Pending"
            let time = formatter.string(from: req.requestTime)
            return "Ride \(req.rideId.prefix(6))... — \(badge) (requested \(time))"
        }
        let header = "You have \(pendingRequests.count) active request(s):"
        return ([header] + lines).joined(separator: "\n")
    }

    /// Formats the user's ride history.
    func historyResponse() -> String {
        guard !rideHistory.isEmpty else {
            return "No ride history found locally. " +
                   "Your completed rides will appear here after your first trip."
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let lines = rideHistory.prefix(5).map { h in
            let date = formatter.string(from: h.completedAt)
            return "\(h.origin) to \(h.destination) — \(date)"
        }
        let header = "Your last \(min(rideHistory.count, 5)) completed ride(s):"
        return ([header] + lines).joined(separator: "\n")
    }

    /// Quick summary of the user's data — used in the greeting when entering offline mode.
    func summaryResponse() -> String {
        var parts: [String] = []
        if !availableRides.isEmpty {
            parts.append("\(availableRides.count) cached ride(s) available")
        }
        if !pendingRequests.isEmpty {
            parts.append("\(pendingRequests.count) active request(s)")
        }
        if !rideHistory.isEmpty {
            parts.append("\(rideHistory.count) ride(s) in history")
        }
        guard !parts.isEmpty else {
            return "I don't have any local data yet. " +
                   "Open the Rides tab while online to cache rides and requests."
        }
        return "I found your local data: " + parts.joined(separator: ", ") +
               ". Tap a topic below to explore."
    }
}
