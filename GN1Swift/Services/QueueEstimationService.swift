import Foundation

/// Standalone service to estimate how long a passenger might wait
/// before a ride departs, based on seat occupancy.
struct QueueEstimationService {
    /// Returns estimated wait time in minutes.
    /// Fully-booked rides are considered "leaving soon" (low wait);
    /// empty rides have more wait time.
    static func estimatedWait(seatsAvailable: Int, totalSeats: Int = 4) -> Int {
        let clamped = min(seatsAvailable, totalSeats)
        let occupancy = Double(totalSeats - clamped) / Double(totalSeats)
        // 0% full → ~10 min wait; 100% full → ~1 min wait
        return max(1, Int((1.0 - occupancy) * 10))
    }
}
