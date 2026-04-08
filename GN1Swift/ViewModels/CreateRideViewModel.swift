import Foundation
import Combine

class CreateRideViewModel: ObservableObject {
    @Published var origin = ""
    @Published var destination = ""
    @Published var zone = ""
    @Published var departureTime = Date().addingTimeInterval(3600)
    @Published var seatsAvailable = 2
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdRideId: String?

    var isValid: Bool {
        !origin.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        !zone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func createRide() {
        guard isValid else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        CloudFunctionsService.shared.createRide(
            origin: origin,
            destination: destination,
            zone: zone,
            departureTime: departureTime,
            seatsAvailable: seatsAvailable
        ) { [weak self] rideId in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let rideId = rideId {
                    self?.createdRideId = rideId
                } else {
                    self?.errorMessage = "Failed to create ride. Please try again."
                }
            }
        }
    }
}
