import Foundation
import FirebaseFirestore

struct Ride: Identifiable {
    let id: String
    let driverId: String
    let driverName: String
    let driverRating: Double
    let origin: String
    let destination: String
    let zone: String
    let departureTime: Date
    let seatsAvailable: Int
    let status: String

    init(from data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.driverId = data["driverId"] as? String ?? ""
        self.driverName = data["driverName"] as? String ?? "Unknown"
        self.driverRating = data["driverRating"] as? Double ?? 0.0
        self.origin = data["origin"] as? String ?? ""
        self.destination = data["destination"] as? String ?? ""
        self.zone = data["zone"] as? String ?? ""
        self.departureTime = (data["departureTime"] as? Timestamp)?.dateValue() ?? Date()
        self.seatsAvailable = data["seatsAvailable"] as? Int ?? 0
        self.status = data["status"] as? String ?? ""
    }
}
