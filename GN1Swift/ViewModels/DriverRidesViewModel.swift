import Foundation
import Combine

/// Handles all data for Driver Mode:
/// the driver's own created rides + all incoming passenger requests.
class DriverRidesViewModel: ObservableObject {

    @Published var myRides: [Ride] = []
    @Published var requests: [RideRequest] = []
    @Published var isLoadingRides = false
    @Published var isLoadingRequests = false

    private var stopRidesListening: (() -> Void)?
    private var stopRequestsListening: (() -> Void)?

    func startListening() {
        guard let userId = UserSession.shared.userId else { return }

        isLoadingRides = true
        stopRidesListening = FirestoreService.shared.listenToDriverRides(driverId: userId) { [weak self] rides in
            DispatchQueue.main.async {
                self?.myRides = rides
                self?.isLoadingRides = false
            }
        }

        isLoadingRequests = true
        stopRequestsListening = FirestoreService.shared.listenToDriverRequests(driverId: userId) { [weak self] reqs in
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

    /// Accepts the request: sets status = "accepted" and decrements seats (handled by CF).
    func accept(_ request: RideRequest) {
        CloudFunctionsService.shared.acceptRide(requestId: request.id) { _ in }
    }

    func reject(_ request: RideRequest) {
        CloudFunctionsService.shared.rejectRide(requestId: request.id) { _ in }
    }
}
