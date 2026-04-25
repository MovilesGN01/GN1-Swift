import Foundation
import Combine
import CoreLocation

class CreateRideViewModel: ObservableObject {
    @Published var originText = ""
    @Published var destinationText = ""
    @Published var zone = ""
    @Published var departureTime = Date().addingTimeInterval(3600)
    @Published var seatsAvailable = 2
    @Published var priceText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdRideId: String?
    /// True when the ride could not reach Firebase and was saved offline instead.
    @Published var rideSavedOffline = false

    var originCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    private let facade: AppFacadeType

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    var isValid: Bool {
        !originText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destinationText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !zone.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedPrice != nil
    }

    /// Returns the price as a positive Double, or nil if the input is invalid.
    var parsedPrice: Double? {
        let trimmed = priceText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Double(trimmed), value > 0 else { return nil }
        return value
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
        guard isValid, let price = parsedPrice else {
            errorMessage = "Please fill in all fields with valid values."
            return
        }
        isLoading = true
        // Offline-first: tries Firebase; falls back to local CoreData on network failure.
        facade.createRideOfflineFirst(
            origin: originText,
            destination: destinationText,
            zone: zone,
            departureTime: departureTime,
            seatsAvailable: seatsAvailable,
            price: price
        ) { [weak self] rideId, savedOffline in
            guard let self = self else { return }
            // Completion is already dispatched to main thread by RideRepository.
            self.isLoading = false
            if savedOffline {
                self.rideSavedOffline = true
            } else if let rideId {
                self.saveCoordinates(rideId: rideId)
                self.createdRideId = rideId
            } else {
                self.errorMessage = "Failed to create ride. Please try again."
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
