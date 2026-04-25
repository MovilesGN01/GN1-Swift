import Foundation
import Combine

/// Listens in real time to rideRequests where passengerId == currentUser.
/// Used in Passenger Mode to show the status of rides the user has requested.
class MyRequestsViewModel: ObservableObject {

    @Published var requests: [RideRequest] = []
    @Published var isLoading = false

    private var stopListening: (() -> Void)?

    func startListening() {
        guard let userId = UserSession.shared.userId else { return }
        // If a listener is already running (e.g. user switched tabs and came back),
        // don't tear it down — that would blank `requests` for a moment and make
        // the "Reserve" button incorrectly re-enable.
        guard stopListening == nil else { return }
        isLoading = requests.isEmpty
        stopListening = FirestoreService.shared.listenToPassengerRequests(passengerId: userId) { [weak self] reqs in
            DispatchQueue.main.async {
                self?.requests = reqs
                self?.isLoading = false
            }
        }
    }

    func stopListeningNow() {
        stopListening?()
    }

    deinit { stopListening?() }

    // MARK: - Helpers

    /// Returns true if the current user already has a non-rejected request for this ride.
    func hasRequested(rideId: String) -> Bool {
        requests.contains { $0.rideId == rideId && $0.status != "rejected" }
    }
}
