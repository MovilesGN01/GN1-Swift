import Foundation
import FirebaseFirestore

struct RideRequest: Identifiable {
    let id: String
    let rideId: String
    let passengerId: String
    var passengerName: String      // var so the ViewModel can back-fill it from `users`
    let driverId: String
    let status: String             // "pending" | "accepted" | "rejected"
    let requestTime: Date          // stored as "requestTime" in Firestore

    init(id: String, from data: [String: Any]) {
        self.id = id
        self.rideId = data["rideId"] as? String ?? ""
        self.passengerId = data["passengerId"] as? String ?? ""
        self.passengerName = data["passengerName"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String ?? ""
        self.status = data["status"] as? String ?? "pending"
        self.requestTime = (data["requestTime"] as? Timestamp)?.dateValue() ?? Date()
    }
}
