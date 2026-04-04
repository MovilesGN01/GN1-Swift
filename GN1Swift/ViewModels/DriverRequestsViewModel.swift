import Foundation
import Combine

class DriverRequestsViewModel: ObservableObject {
    @Published var requests: [RideRequest] = []
    @Published var isLoading = false

    private var stopListening: (() -> Void)?
    private let rideId: String?

    init(rideId: String? = nil) {
        self.rideId = rideId
    }

    func startListening() {
        guard let userId = UserSession.shared.userId else { return }
        isLoading = true

        let handler: ([RideRequest]) -> Void = { [weak self] reqs in
            self?.enrichAndPublish(reqs)
        }

        if let rideId = rideId {
            stopListening = FirestoreService.shared.listenToRideRequests(rideId: rideId, completion: handler)
        } else {
            stopListening = FirestoreService.shared.listenToDriverRequests(driverId: userId, completion: handler)
        }
    }

    func stopListeningNow() {
        stopListening?()
    }

    deinit {
        stopListening?()
    }

    // MARK: - Actions

    /// Reject a passenger request.
    func reject(_ request: RideRequest) {
        CloudFunctionsService.shared.rejectRide(requestId: request.id) { success in
            if !success { print("Failed to reject request \(request.id)") }
        }
    }

    /// Accepts the request: sets status = "accepted" and decrements seats (handled by CF).
    func accept(_ request: RideRequest) {
        CloudFunctionsService.shared.acceptRide(requestId: request.id) { _ in }
    }

    // MARK: - Name Enrichment

    /// For any request where passengerName is missing, back-fill it from the users collection.
    private func enrichAndPublish(_ reqs: [RideRequest]) {
        var enriched = reqs
        let unknown = enriched.indices.filter {
            enriched[$0].passengerName == "Unknown" && !enriched[$0].passengerId.isEmpty
        }

        guard !unknown.isEmpty else {
            DispatchQueue.main.async {
                self.requests = enriched
                self.isLoading = false
            }
            return
        }

        let group = DispatchGroup()
        for i in unknown {
            let passengerId = enriched[i].passengerId
            group.enter()
            FirestoreService.shared.fetchUserName(userId: passengerId) { name in
                if let name = name { enriched[i].passengerName = name }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.requests = enriched
            self?.isLoading = false
        }
    }
}
