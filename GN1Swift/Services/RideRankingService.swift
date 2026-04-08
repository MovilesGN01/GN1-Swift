import Foundation

/// Ranks a list of rides by quality: highest driver rating first,
/// then soonest departure, then most seats available.
struct RideRankingService {
    static func rank(_ rides: [Ride]) -> [Ride] {
        rides.sorted { a, b in
            if a.driverRating != b.driverRating {
                return a.driverRating > b.driverRating
            }
            if a.departureTime != b.departureTime {
                return a.departureTime < b.departureTime
            }
            return a.seatsAvailable > b.seatsAvailable
        }
    }
}
