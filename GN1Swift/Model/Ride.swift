import Foundation
import FirebaseFirestore

struct Ride: Identifiable {
    let id: String
    let driverId: String
    let driverName: String
    let driverRating: Double
    let driverGender: String?
    let origin: String
    let destination: String
    let zone: String
    let departureTime: Date
    let seatsAvailable: Int
    let status: String
    let price: Double
    let originLat: Double?
    let originLng: Double?
    let destinationLat: Double?
    let destinationLng: Double?

    // Direct memberwise init — used by the CoreData layer to reconstruct Ride values
    // without depending on Firestore Timestamp.
    init(
        id: String, driverId: String, driverName: String,
        driverRating: Double, driverGender: String?,
        origin: String, destination: String, zone: String,
        departureTime: Date, seatsAvailable: Int,
        status: String, price: Double,
        originLat: Double? = nil, originLng: Double? = nil,
        destinationLat: Double? = nil, destinationLng: Double? = nil
    ) {
        self.id = id; self.driverId = driverId; self.driverName = driverName
        self.driverRating = driverRating; self.driverGender = driverGender
        self.origin = origin; self.destination = destination; self.zone = zone
        self.departureTime = departureTime; self.seatsAvailable = seatsAvailable
        self.status = status; self.price = price
        self.originLat = originLat; self.originLng = originLng
        self.destinationLat = destinationLat; self.destinationLng = destinationLng
    }

    init(from data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.driverId = data["driverId"] as? String ?? ""
        self.driverName = data["driverName"] as? String ?? "Unknown"
        self.driverRating = data["driverRating"] as? Double ?? 0.0
        self.driverGender = data["driverGender"] as? String
        self.origin = data["origin"] as? String ?? ""
        self.destination = data["destination"] as? String ?? ""
        self.zone = data["zone"] as? String ?? ""
        self.departureTime = (data["departureTime"] as? Timestamp)?.dateValue() ?? Date()
        self.seatsAvailable = data["seatsAvailable"] as? Int ?? 0
        self.status = data["status"] as? String ?? ""
        self.price = data["price"] as? Double ?? 0.0
        self.originLat = data["originLat"] as? Double
        self.originLng = data["originLng"] as? Double
        self.destinationLat = data["destinationLat"] as? Double
        self.destinationLng = data["destinationLng"] as? Double
    }
}
