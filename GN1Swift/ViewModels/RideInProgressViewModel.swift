import Foundation
import Combine
import MapKit
import CoreLocation

class RideInProgressViewModel: ObservableObject {

    @Published var acceptedPassengers: [RideRequest] = []
    @Published var isFinishing = false
    @Published var errorMessage: String?
    @Published var route: MKRoute?

    let ride: Ride

    private var stopListening: (() -> Void)?

    var originCoordinate: CLLocationCoordinate2D? {
        guard let lat = ride.originLat, let lng = ride.originLng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var destinationCoordinate: CLLocationCoordinate2D? {
        guard let lat = ride.destinationLat, let lng = ride.destinationLng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    init(ride: Ride) {
        self.ride = ride
    }

    func startListening() {
        stopListening = FirestoreService.shared.listenToAcceptedPassengers(rideId: ride.id) { [weak self] passengers in
            DispatchQueue.main.async {
                self?.acceptedPassengers = passengers
            }
        }
        resolveAndFetchRoute()
    }

    func stopListeningNow() { stopListening?() }

    deinit { stopListening?() }

    // MARK: - Route

    private func resolveAndFetchRoute() {
        if let origin = originCoordinate, let destination = destinationCoordinate {
            fetchRoute(from: origin, to: destination)
        } else {
            resolveWithGeocoder()
        }
    }

    private func fetchRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        MKDirections(request: request).calculate { [weak self] response, error in
            if let error = error {
                print("[Route] MKDirections error:", error.localizedDescription)
            }
            DispatchQueue.main.async {
                self?.route = response?.routes.first
            }
        }
    }

    private func resolveWithGeocoder() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(ride.origin) { [weak self] placemarks, _ in
            guard let self, let originCoord = placemarks?.first?.location?.coordinate else { return }
            geocoder.geocodeAddressString(self.ride.destination) { placemarks, _ in
                guard let destCoord = placemarks?.first?.location?.coordinate else { return }
                self.fetchRoute(from: originCoord, to: destCoord)
            }
        }
    }

    // MARK: - Actions

    func finishRide(completion: @escaping () -> Void) {
        isFinishing = true
        CloudFunctionsService.shared.finishRide(rideId: ride.id) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                DispatchQueue.main.async {
                    self.isFinishing = false
                    self.errorMessage = "Failed to finish ride. Please try again."
                }
                return
            }
            FirestoreService.shared.markRideRequestsCompleted(rideId: self.ride.id)
            CloudFunctionsService.shared.updateUserAnalytics {
                DispatchQueue.main.async {
                    self.isFinishing = false
                    completion()
                }
            }
        }
    }
}
