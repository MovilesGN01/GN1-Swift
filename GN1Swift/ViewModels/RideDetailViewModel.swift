import Foundation
import Combine

class RideDetailViewModel: ObservableObject {
    @Published var isRequesting = false
    @Published var requestSuccess = false
    @Published var alreadyRequested = false
    @Published var errorMessage: String?

    let ride: Ride

    init(ride: Ride) {
        self.ride = ride
    }

    /// Call from onAppear to pre-disable the button if the user already requested this ride.
    func checkExistingRequest() {
        guard let userId = UserSession.shared.userId else { return }
        FirestoreService.shared.hasExistingRequest(rideId: ride.id, passengerId: userId) { [weak self] exists in
            DispatchQueue.main.async {
                if exists { self?.alreadyRequested = true }
            }
        }
    }

    func requestRide() {
        isRequesting = true
        CloudFunctionsService.shared.requestRide(rideId: ride.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isRequesting = false
                switch result {
                case .success:
                    self?.requestSuccess = true
                case .alreadyRequested:
                    self?.alreadyRequested = true
                    self?.errorMessage = "You already requested this ride."
                case .failure:
                    self?.errorMessage = "Failed to reserve ride. Please try again."
                }
            }
        }
    }
}
