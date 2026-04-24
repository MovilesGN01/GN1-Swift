import Foundation

/// Responsible for pushing locally-created ("pending") rides to Firebase
/// when connectivity is restored. Call `syncPendingRides()` on app launch
/// or when the driver's rides screen appears.
final class SyncManager {

    static let shared = SyncManager()

    private let localSource: RideLocalDataSource
    private let cloudService: CloudFunctionsService

    init(
        localSource: RideLocalDataSource = RideLocalDataSource(),
        cloudService: CloudFunctionsService = .shared
    ) {
        self.localSource = localSource
        self.cloudService = cloudService
    }

    // MARK: - Sync

    /// Iterates every pending ride and either pushes it to Firebase or marks
    /// it as expired (if its departure time has already passed).
    ///
    /// - Returns: rides that expired before they could be synced.
    func syncPendingRides() async -> [Ride] {
        let pending = await localSource.fetchPendingRides()
        var expired: [Ride] = []

        for ride in pending {
            if Date() < ride.departureTime {
                // Still in the future — try to push to Firebase
                let rideId = await pushToFirebase(ride)
                if rideId != nil {
                    await localSource.deleteRide(id: ride.id)
                }
                // If nil (still offline), leave it pending for the next attempt.
            } else {
                // Departure time has passed — will never be valid. Remove locally.
                await localSource.deleteRide(id: ride.id)
                expired.append(ride)
            }
        }
        return expired
    }

    // MARK: - Private

    private func pushToFirebase(_ ride: Ride) async -> String? {
        await withCheckedContinuation { continuation in
            cloudService.createRide(
                origin: ride.origin,
                destination: ride.destination,
                zone: ride.zone,
                departureTime: ride.departureTime,
                seatsAvailable: ride.seatsAvailable,
                price: ride.price
            ) { rideId in
                continuation.resume(returning: rideId)
            }
        }
    }
}
