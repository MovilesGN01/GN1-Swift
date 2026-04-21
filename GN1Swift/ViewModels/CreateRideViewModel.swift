import Foundation
import Combine
import CoreLocation

class CreateRideViewModel: ObservableObject {
    @Published var originText = ""
    @Published var destinationText = ""
    @Published var zone = ""
    @Published var departureTime = Date().addingTimeInterval(3600)
    @Published var seatsAvailable = 2
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdRideId: String?


    var originCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    private let facade: AppFacadeType

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    var isValid: Bool {
        !originText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destinationText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !zone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func setOrigin(name: String, coordinate: CLLocationCoordinate2D) {
        originText = name
        originCoordinate = coordinate
    }

    func setDestination(name: String, coordinate: CLLocationCoordinate2D) {
        destinationText = name
        destinationCoordinate = coordinate
    }

    func createRide() {
        guard isValid else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        CloudFunctionsService.shared.createRide(
            origin: originText,
            destination: destinationText,
        facade.createRide(
            origin: origin,
            destination: destination,
            zone: zone,
            departureTime: departureTime,
            seatsAvailable: seatsAvailable
        ) { [weak self] rideId in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let rideId = rideId {
                    self.saveCoordinates(rideId: rideId)
                    self.createdRideId = rideId
                } else {
                    self.errorMessage = "Failed to create ride. Please try again."
                }
            }
        }
    }

    private func saveCoordinates(rideId: String) {
        guard let oLat = originCoordinate?.latitude,
              let oLng = originCoordinate?.longitude,
              let dLat = destinationCoordinate?.latitude,
              let dLng = destinationCoordinate?.longitude else { return }
        FirestoreService.shared.updateRideCoordinates(
            rideId: rideId,
            originLat: oLat, originLng: oLng,
            destinationLat: dLat, destinationLng: dLng
        )
    }
}
