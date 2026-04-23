import Foundation

/// Orchestrates the online-first ride-loading strategy and offline-first ride creation:
///
///  Loading: Fetch from Firebase first → persist to CoreData → `onSuccess`.
///           On network failure → read CoreData → `onFallback`.
///
///  Creating: Try Firebase first → on success call back with the rideId.
///            On network failure → persist locally with status "pending" → call back
///            with (localId, savedOffline: true). SyncManager will push it later.
final class RideRepository {

    static let shared = RideRepository()

    private let localSource: RideLocalDataSource
    private let cloudService: CloudFunctionsService

    init(
        localSource: RideLocalDataSource = RideLocalDataSource(),
        cloudService: CloudFunctionsService = .shared
    ) {
        self.localSource = localSource
        self.cloudService = cloudService
    }

    // MARK: - Online-First Fetch

    /// Loads all available rides using an online-first strategy.
    ///
    /// - `onSuccess`:  called on the main thread with fresh Firebase data.
    ///                 CoreData is updated before this fires.
    /// - `onFallback`: called on the main thread with cached CoreData data when
    ///                 Firebase is unreachable. May be an empty array on first launch.
    func fetchAllRides(
        onSuccess: @escaping ([Ride]) -> Void,
        onFallback: @escaping ([Ride]) -> Void
    ) {
        Task {
            // ── Phase 1: Firebase (network, primary source) ───────────────
            let result: Result<[Ride], Error> = await withCheckedContinuation { continuation in
                cloudService.getAllAvailableRides { (result: Result<[Ride], Error>) in
                    continuation.resume(returning: result)
                }
            }

            switch result {
            case .success(let rides):
                // ── Phase 2: Persist + update UI ─────────────────────────
                await localSource.saveRides(rides)
                await MainActor.run { onSuccess(rides) }

            case .failure:
                // ── Fallback: CoreData (no network) ───────────────────────
                let cached = await localSource.fetchRides()
                await MainActor.run { onFallback(cached) }
            }
        }
    }

    // MARK: - Offline-First Create

    /// Tries to create the ride in Firebase. If the network call fails, the ride is
    /// persisted locally with status "pending" and synced later by SyncManager.
    ///
    /// - completion: called on the **main thread** with
    ///   - `(rideId, false)` — created in Firebase successfully
    ///   - `(localId, true)` — saved offline; will be synced when online
    ///   - `(nil, false)`    — auth data missing; cannot create
    func createRideOfflineFirst(
        origin: String,
        destination: String,
        zone: String,
        departureTime: Date,
        seatsAvailable: Int,
        price: Double,
        completion: @escaping (String?, Bool) -> Void
    ) {
        Task {
            // ── Phase 1: try Firebase ──────────────────────────────────────
            let rideId: String? = await withCheckedContinuation { continuation in
                cloudService.createRide(
                    origin: origin,
                    destination: destination,
                    zone: zone,
                    departureTime: departureTime,
                    seatsAvailable: seatsAvailable,
                    price: price
                ) { continuation.resume(returning: $0) }
            }

            if let rideId {
                await MainActor.run { completion(rideId, false) }
                return
            }

            // ── Phase 2: save locally ─────────────────────────────────────
            let session = UserSession.shared
            guard let driverId = session.userId else {
                await MainActor.run { completion(nil, false) }
                return
            }

            let localId = UUID().uuidString
            let localRide = Ride(
                id: localId,
                driverId: driverId,
                driverName: session.name ?? "Driver",
                driverRating: 5.0,
                driverGender: session.gender?.rawValue,
                origin: origin,
                destination: destination,
                zone: zone,
                departureTime: departureTime,
                seatsAvailable: seatsAvailable,
                status: "pending",
                price: price
            )
            await localSource.savePendingRide(localRide)
            await MainActor.run { completion(localId, true) }
        }
    }
}
