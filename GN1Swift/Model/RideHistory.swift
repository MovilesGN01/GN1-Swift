import Foundation
import FirebaseFirestore

struct RideHistory: Identifiable {
    let id: String
    let rideId: String
    let passengerId: String
    let driverId: String
    let origin: String
    let destination: String
    let zone: String
    let completedAt: Date
    let passengerRating: Double
    let driverRating: Double

    init(id: String, from data: [String: Any]) {
        self.id = id
        self.rideId = data["rideId"] as? String ?? ""
        self.passengerId = data["passengerId"] as? String ?? ""
        self.driverId = data["driverId"] as? String ?? ""
        self.origin = data["origin"] as? String ?? ""
        self.destination = data["destination"] as? String ?? ""
        self.zone = data["zone"] as? String ?? ""
        self.passengerRating = data["passengerRating"] as? Double ?? 0.0
        self.driverRating = data["driverRating"] as? Double ?? 0.0
        self.completedAt = (data["completedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
