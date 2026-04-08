import Foundation
import Combine

/// Handles all data for Driver Mode:
/// the driver's own created rides + all incoming passenger requests.
class DriverRidesViewModel: ObservableObject {

    @Published var myRides: [Ride] = []
    @Published var requests: [RideRequest] = []
    @Published var isLoadingRides = false
    @Published var isLoadingRequests = false

    private let facade: AppFacadeType
    private var stopRidesListening: (() -> Void)?
    private var stopRequestsListening: (() -> Void)?

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
    }

    func stopListeningNow() {
        stopRidesListening?()
        stopRequestsListening?()
    }

    deinit {
        stopRidesListening?()
        stopRequestsListening?()
    }

    // MARK: - Actions

    /// Accepts the request: calls CF then writes status directly to Firestore as a fallback.
    func accept(_ request: RideRequest) {
        facade.acceptRide(requestId: request.id) { [weak self] success in
            print("[DriverVM] acceptRide CF success: \(success)")
            // Write directly so the passenger listener always sees the update
            self?.facade.updateRequestStatus(requestId: request.id, status: "accepted")
        }
    }

    func reject(_ request: RideRequest) {
        facade.rejectRide(requestId: request.id) { [weak self] success in
            print("[DriverVM] rejectRide CF success: \(success)")
            self?.facade.updateRequestStatus(requestId: request.id, status: "rejected")
        }
    }
}
