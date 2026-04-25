import Foundation
import Combine

/// Handles all data for Passenger Mode:
/// available marketplace rides (excluding own) + recommended rides.
/// Pair with MyRequestsViewModel for the "My Requests" section.
class PassengerRidesViewModel: ObservableObject {

    @Published var allRides: [Ride] = []
    @Published var filteredRides: [Ride] = []
    @Published var recommendedRides: [Ride] = []
    @Published var zones: [String] = ["All"]
    @Published var isLoading = false
    /// True while rides are being served from the local CoreData cache and the
    /// remote Firebase fetch has not yet responded. Clears as soon as fresh data arrives.
    @Published var isOffline = false

    /// Ride IDs for which the current user has an active (pending/accepted) request.
    /// Populated once at startup via `loadFullRideState()`.
    @Published var requestedRideIds: Set<String> = []

    /// Ride IDs that appear in the passenger's ride history (completed rides).
    /// Populated once at startup via `loadFullRideState()`.
    @Published var completedRideIds: Set<String> = []

    @Published var selectedZone: String = "All" { didSet { filterRides() } }
    @Published var minRating: Double = 0.0 { didSet { filterRides() } }
    @Published var minSeats: Int = 1 { didSet { filterRides() } }

    private let facade: AppFacadeType
    private let localSource = RideLocalDataSource()
    private var currentUserId: String { UserSession.shared.userId ?? "" }

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    // MARK: - Full State Load (startup)

    /// Loads rides (online-first) while simultaneously fetching requests and history
    /// in parallel. Call this instead of `loadRides()` when the app launches so the
    /// "Reserve" button shows the correct disabled state immediately.
    func loadFullRideState() {
        guard !currentUserId.isEmpty else { loadRides(); return }
        isLoading = true

        // Recommended rides — Firebase only, fire-and-forget
        facade.fetchRecommendedRides { [weak self] rides in
            DispatchQueue.main.async {
                guard let self else { return }
                let filtered = rides.filter { $0.driverId != self.currentUserId }
                self.recommendedRides = RideRankingService.rank(filtered)
            }
        }

        // Rides — online-first:
        //   onSuccess  → Firebase responded; UI shows fresh data, CoreData updated.
        //   onFallback → Firebase unreachable; UI shows cached data with offline banner.
        facade.fetchAllRidesOnlineFirst { [weak self] rides in
            guard let self else { return }
            self.apply(rides: rides)
            self.isLoading = false
            self.isOffline = false
        } onFallback: { [weak self] rides in
            guard let self else { return }
            self.apply(rides: rides)
            self.isLoading = false
            self.isOffline = true
        }

        // Requests + History — online-first with CoreData fallback
        let userId = currentUserId
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Phase 1: serve last known state from CoreData immediately
            let cachedRequests = await self.localSource.fetchPassengerRequests(for: userId)
            let cachedHistory  = await self.localSource.fetchRideHistory(for: userId)
            self.requestedRideIds = Set(cachedRequests.map(\.rideId))
            self.completedRideIds = Set(cachedHistory.map(\.rideId))

            // Phase 2: attempt Firebase in parallel
            async let rqTask   = self.fetchRequestsResult(userId: userId)
            async let histTask = self.fetchHistoryResult(userId: userId)
            let (rqResult, histResult) = await (rqTask, histTask)

            // Phase 3: on success → update CoreData + UI; on failure → keep CoreData
            if case .success(let requests) = rqResult {
                await self.localSource.savePassengerRequests(requests, for: userId)
                self.requestedRideIds = Set(requests.map(\.rideId))
            }
            if case .success(let history) = histResult {
                await self.localSource.saveRideHistory(history, for: userId)
                self.completedRideIds = Set(history.map(\.rideId))
            }
        }
    }

    // MARK: - Online-First Load

    func loadRides() {
        isLoading = true

        // Recommended rides — Firebase only
        facade.fetchRecommendedRides { [weak self] rides in
            DispatchQueue.main.async {
                guard let self else { return }
                let filtered = rides.filter { $0.driverId != self.currentUserId }
                self.recommendedRides = RideRankingService.rank(filtered)
            }
        }

        // All rides — online-first:
        //   Firebase is always tried first. CoreData is only read when Firebase fails.
        facade.fetchAllRidesOnlineFirst { [weak self] rides in
            guard let self else { return }
            self.apply(rides: rides)
            self.isLoading = false
            self.isOffline = false
        } onFallback: { [weak self] rides in
            guard let self else { return }
            self.apply(rides: rides)
            self.isLoading = false
            self.isOffline = true
        }
    }

    // MARK: - Filtering

    func filterRides() {
        var result = allRides
        if selectedZone != "All" {
            result = result.filter { $0.zone == selectedZone }
        }
        if minRating > 0 {
            result = result.filter { $0.driverRating >= minRating }
        }
        result = result.filter { $0.seatsAvailable >= minSeats }
        filteredRides = RideRankingService.rank(result)
    }

    func applyFilters() { filterRides() }

    // MARK: - Async Bridges (Result-based — distinguishes offline from empty)

    private func fetchRequestsResult(userId: String) async -> Result<[RideRequest], Error> {
        await withCheckedContinuation { continuation in
            FirestoreService.shared.fetchPassengerRequestsResult(passengerId: userId) {
                continuation.resume(returning: $0)
            }
        }
    }

    private func fetchHistoryResult(userId: String) async -> Result<[RideHistory], Error> {
        await withCheckedContinuation { continuation in
            FirestoreService.shared.fetchRideHistoryResult(passengerId: userId) {
                continuation.resume(returning: $0)
            }
        }
    }

    // MARK: - Private

    /// Applies a ride list from any source (local or remote) to published state.
    private func apply(rides: [Ride]) {
        let marketplace = rides.filter { $0.driverId != currentUserId }
        allRides = marketplace
        extractZones(from: marketplace)
        filterRides()
    }

    private func extractZones(from rides: [Ride]) {
        let sorted = Set(rides.compactMap { $0.zone.isEmpty ? nil : $0.zone }).sorted()
        zones = ["All"] + sorted
    }
}
