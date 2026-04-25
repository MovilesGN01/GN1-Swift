import CoreLocation
import Combine
import FirebaseAuth

final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published var currentCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermissionAndStart() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = location.coordinate
        if let userId = Auth.auth().currentUser?.uid {
            FirestoreService.shared.updateUserLocation(
                userId: userId,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
