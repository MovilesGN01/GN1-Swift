import Foundation
import FirebaseFunctions
import FirebaseAuth

// MARK: - Result Types

enum RequestRideResult {
    case success
    case alreadyRequested   // CF returned "already-exists"
    case failure
}

// MARK: - Service

final class CloudFunctionsService {

    static let shared = CloudFunctionsService()
    private let functions = Functions.functions(region: "us-central1")
    private init() {}
    // MARK: - User

    func createUserDocument(completion: @escaping (Bool) -> Void) {
        guard let name = UserSession.shared.name,
              let email = UserSession.shared.email,
              let role = UserSession.shared.role else {
            completion(false); return
        }
        let data: [String: Any] = ["name": name, "email": email, "role": role]
        functions.httpsCallable("createUserDocument").call(data) { _, error in
            if let error = error { print("createUserDocument error:", error.localizedDescription) }
            completion(error == nil)
        }
    }

    func updateUserAnalytics(completion: @escaping () -> Void = {}) {
        functions.httpsCallable("updateUserAnalytics").call { _, error in
            if let error = error { print("Analytics error:", error.localizedDescription) }
            completion()
        }
    }

    // MARK: - Weather

    func updateWeather() {
        functions.httpsCallable("weatherAwareRides").call { _, _ in }
    }

    // MARK: - Rides — Passenger

    func getAllAvailableRides(completion: @escaping ([Ride]) -> Void) {
        functions.httpsCallable("getAllAvailableRides").call { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any],
                  let array = data["rides"] as? [[String: Any]] else {
                completion([]); return
            }
            completion(array.map { Ride(from: $0) })
        }
    }

    func getAvailableRides(zone: String, completion: @escaping ([Ride]) -> Void) {
        functions.httpsCallable("getAvailableRides").call(["zone": zone]) { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any],
                  let array = data["rides"] as? [[String: Any]] else {
                completion([]); return
            }
            completion(array.map { Ride(from: $0) })
        }
    }

    func getRecommendedRides(completion: @escaping ([Ride]) -> Void) {
        functions.httpsCallable("getRecommendedRides").call { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any],
                  let array = data["rides"] as? [[String: Any]] else {
                completion([]); return
            }
            completion(array.map { Ride(from: $0) })
        }
    }

    func getRideRecommendations(completion: @escaping ([Ride]) -> Void) {
        functions.httpsCallable("getRideRecommendations").call { result, error in
            if let error = error {
                print("getRideRecommendations error:", error.localizedDescription)
                completion([]); return
            }
            // The CF returns the array directly, not wrapped in a dictionary.
            guard let array = result?.data as? [[String: Any]] else {
                completion([]); return
            }
            completion(array.map { Ride(from: $0) })
        }
    }

    /// Default no-op completion keeps call sites that don't need the result.
    func requestRide(rideId: String,
                     completion: @escaping (RequestRideResult) -> Void = { _ in }) {
        let passengerName = UserSession.shared.name ?? ""
        let payload: [String: Any] = ["rideId": rideId, "passengerName": passengerName]
        functions.httpsCallable("requestRide").call(payload) { _, error in
            if let error = error {
                print("requestRide error:", error.localizedDescription)
                let nsError = error as NSError
                // FunctionsErrorCode.alreadyExists == 6
                if nsError.domain == FunctionsErrorDomain, nsError.code == FunctionsErrorCode.alreadyExists.rawValue {
                    completion(.alreadyRequested)
                } else {
                    completion(.failure)
                }
                return
            }
            completion(.success)
        }
    }

    // MARK: - Rides — Driver

    /// Returns the newly created rideId on success, nil on failure.
    func createRide(origin: String,
                    destination: String,
                    zone: String,
                    departureTime: Date,
                    seatsAvailable: Int,
                    completion: @escaping (String?) -> Void) {
        
        guard let userId = Auth.auth().currentUser?.uid,
              let driverName = UserSession.shared.name else {
            completion(nil)
            return
        }
        
        let data: [String: Any] = [
            "driverName": driverName,
            "driverRating": 5.0,
            "origin": origin,
            "destination": destination,
            "zone": zone,
            "departureTime": departureTime.timeIntervalSince1970 * 1000, // milisegundos
            "seatsAvailable": seatsAvailable
        ]
        
        functions.httpsCallable("createRide").call(data) { result, error in
            
            if let error = error {
                print("createRide error:", error.localizedDescription)
                completion(nil)
                return
            }
            
            if let resp = result?.data as? [String: Any],
               let rideId = resp["rideId"] as? String {
                completion(rideId)
            } else {
                completion(nil)
            }
        }
    }

    func acceptRide(requestId: String, completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("acceptRide").call(["requestId": requestId]) { _, error in
            completion(error == nil)
        }
    }

    func rejectRide(requestId: String, completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("rejectRide").call(["requestId": requestId]) { _, error in
            completion(error == nil)
        }
    }

    /// Driver explicitly starts the ride → sets rides.status = "in_progress".
    func startRide(rideId: String, completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("startRide").call(["rideId": rideId]) { _, error in
            if let error = error { print("startRide error:", error.localizedDescription) }
            completion(error == nil)
        }
    }

    /// Driver completes the ride → sets status = "completed", creates rideHistory, updates analytics.
    func completeRide(rideId: String, completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("completeRide").call(["rideId": rideId]) { _, error in
            if let error = error { print("completeRide error:", error.localizedDescription) }
            completion(error == nil)
        }
    }

    /// Driver finishes a ride in progress → "completed", rideHistory per passenger,
    /// requests marked "completed", analytics updated.
    func finishRide(rideId: String, completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("finishRide").call(["rideId": rideId]) { _, error in
            if let error = error { print("finishRide error:", error.localizedDescription) }
            completion(error == nil)
        }
    }

    // MARK: - Chatbot

    func chatbot(message: String, completion: @escaping (String?) -> Void) {
        functions.httpsCallable("chatbot").call(["message": message]) { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any],
                  let reply = data["reply"] as? String else {
                completion(nil); return
            }
            completion(reply)
        }
    }
}
