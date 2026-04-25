import Foundation
import Combine

class ActiveRideViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    let ride: Ride

    var isDriver: Bool {
        UserSession.shared.userId == ride.driverId
    }

    init(ride: Ride) {
        self.ride = ride
    }

    /// Completes the ride via CF:
    /// sets status = "completed", creates rideHistory for all accepted passengers, updates analytics.
    func completeRide(completion: @escaping () -> Void) {
        isLoading = true
        CloudFunctionsService.shared.completeRide(rideId: ride.id) { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoading = false
                if success {
                    completion()
                } else {
                    self?.errorMessage = "Failed to complete ride. Please try again."
                }
            }
        }
    }
}
