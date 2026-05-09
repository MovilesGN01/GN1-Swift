import Foundation
import Combine

/// Handles all data for Driver Mode:
/// the driver's own created rides + all incoming passenger requests.
class DriverRidesViewModel: ObservableObject {

    @Published var myRides: [Ride] = []
    /// Rides created locally while offline, not yet synced to Firebase.
    @Published var pendingRides: [Ride] = []
    /// Warning messages shown to the driver when a pending ride expired before it could sync.
    @Published var expiredRideMessages: [String] = []
    @Published var requests: [RideRequest] = []
    @Published var isLoadingRides = false
    @Published var isLoadingRequests = false
    @Published var processingRequestId: String?

    /// Combined list: locally pending rides appear above Firebase rides.
    var allRides: [Ride] { pendingRides + myRides }

    /// First message to surface to the user (consumed by the View's alert).
    var activeExpiredMessage: String? { expiredRideMessages.first }

    private let facade: AppFacadeType
    private let localSource = RideLocalDataSource()
    private var stopRidesListening: (() -> Void)?
    private var stopRequestsListening: (() -> Void)?
    private var syncTimer: Timer?

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    func startListening() {
        guard let userId = UserSession.shared.userId else { return }

        isLoadingRides = true
        stopRidesListening = facade.listenToDriverRides(driverId: userId) { [weak self] rides in
            DispatchQueue.main.async {
                self?.myRides = rides
                self?.isLoadingRides = false
            }
        }

        isLoadingRequests = true
        stopRequestsListening = facade.listenToDriverRequests(driverId: userId) { [weak self] reqs in
            DispatchQueue.main.async {
                self?.requests = reqs
                self?.isLoadingRequests = false
            }
        }

        // Show pending rides immediately, then attempt sync in background.
        loadPendingRides()
        syncAndRefresh()

        // Periodic sync: detects expired rides and new connections without
        // requiring the driver to leave and return to the tab.
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.syncAndRefresh()
        }
    }

    /// Refreshes the pending-rides list from CoreData without triggering a sync.
    func loadPendingRides() {
        Task {
            let pending = await localSource.fetchPendingRides()
            await MainActor.run { self.pendingRides = pending }
        }
    }

    /// Runs SyncManager, then refreshes the pending list and surfaces expired-ride warnings.
    func syncAndRefresh() {
        Task {
            let expired = await SyncManager.shared.syncPendingRides()
            let pending = await localSource.fetchPendingRides()
            await MainActor.run {
                self.pendingRides = pending
                let messages = expired.map {
                    "\"\($0.origin) → \($0.destination)\" could not be created — it expired while offline."
                }
                self.expiredRideMessages.append(contentsOf: messages)
            }
        }
    }

    /// Called by the View after the user dismisses an expired-ride alert.
    func dismissExpiredMessage() {
        guard !expiredRideMessages.isEmpty else { return }
        expiredRideMessages.removeFirst()
    }

    func stopListeningNow() {
        stopRidesListening?()
        stopRequestsListening?()
        syncTimer?.invalidate()
        syncTimer = nil
    }

    deinit {
        stopRidesListening?()
        stopRequestsListening?()
        syncTimer?.invalidate()
    }

    // MARK: - Actions

    /// Accepts the request: calls CF then writes status directly to Firestore as a fallback.
    func accept(_ request: RideRequest) {
        guard processingRequestId == nil else { return }
        processingRequestId = request.id
        facade.acceptRide(requestId: request.id) { [weak self] success in
            print("[DriverVM] acceptRide CF success: \(success)")
            self?.facade.updateRequestStatus(requestId: request.id, status: "accepted")
            DispatchQueue.main.async { self?.processingRequestId = nil }
        }
    }

    func reject(_ request: RideRequest) {
        guard processingRequestId == nil else { return }
        processingRequestId = request.id
        facade.rejectRide(requestId: request.id) { [weak self] success in
            print("[DriverVM] rejectRide CF success: \(success)")
            self?.facade.updateRequestStatus(requestId: request.id, status: "rejected")
            DispatchQueue.main.async { self?.processingRequestId = nil }
        }
    }
}
