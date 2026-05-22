import Foundation
import FirebaseFunctions
import FirebaseAuth

// MARK: - Result Types

enum RequestRideResult {
    case success
    case alreadyRequested   // CF returned "already-exists"
    case failure
}

struct SubmitRideRatingResult {
    let success: Bool
    let pointsAwarded: Int
    let newLevel: Int?
    let newTotalPoints: Int?
    let badgeUnlocked: Badge?
    let message: String?

    static let failure = SubmitRideRatingResult(
        success: false,
        pointsAwarded: 0,
        newLevel: nil,
        newTotalPoints: nil,
        badgeUnlocked: nil,
        message: "Failed to submit rating"
    )
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
        var data: [String: Any] = ["name": name, "email": email, "role": role]
        if let gender = UserSession.shared.gender {
            data["gender"] = gender.rawValue
        }
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

    func updateWeather(completion: @escaping () -> Void = {}) {
        functions.httpsCallable("weatherAwareRides").call { _, _ in completion() }
    }

    // MARK: - Analytics

    func calculateTopZones(completion: @escaping () -> Void = {}) {
        functions.httpsCallable("calculateTopZones").call { _, _ in completion() }
    }

    func calculatePeakHours(completion: @escaping () -> Void = {}) {
        functions.httpsCallable("calculatePeakHours").call { _, _ in completion() }
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

    /// Result-based overload used by RideRepository for online-first loading.
    /// Returns .failure on any network/server error so the caller can distinguish
    /// "Firebase unreachable" from "Firebase returned zero rides".
    func getAllAvailableRides(completion: @escaping (Result<[Ride], Error>) -> Void) {
        functions.httpsCallable("getAllAvailableRides").call { result, error in
            if let error {
                completion(.failure(error)); return
            }
            guard let data = result?.data as? [String: Any],
                  let array = data["rides"] as? [[String: Any]] else {
                completion(.success([])); return
            }
            completion(.success(array.map { Ride(from: $0) }))
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
                    price: Double,
                    completion: @escaping (String?) -> Void) {

        guard Auth.auth().currentUser?.uid != nil,
              let driverName = UserSession.shared.name else {
            completion(nil)
            return
        }

        let data: [String: Any] = [
            "driverName": driverName,
            "driverGender": UserSession.shared.gender?.rawValue ?? "",
            "driverRating": 5.0,
            "origin": origin,
            "destination": destination,
            "zone": zone,
            "departureTime": departureTime.timeIntervalSince1970 * 1000,
            "seatsAvailable": seatsAvailable,
            "price": price
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
    
    // MARK: - Reports

    func reportUser(report: IncidentReport, completion: @escaping (Bool) -> Void) {
        let payload: [String: Any] = [
            "reportedUserId": report.reportedUserId,
            "reportedUserName": report.reportedUserName,
            "category": report.category.rawValue,
            "description": report.description
        ]
        functions.httpsCallable("reportUser").call(payload) { _, error in
            if let error = error { print("reportUser error:", error.localizedDescription) }
            completion(error == nil)
        }
    }

    // MARK: - Gamification
    
    func fetchGamificationProfile(userId: String, completion: @escaping (UserGamification?) -> Void) {
        functions.httpsCallable("getGamificationProfile").call(["userId": userId]) { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any] else {
                completion(nil); return
            }

            // Supports both payload styles:
            // 1) direct profile object
            // 2) wrapped response { success, data }
            let profilePayload = (data["data"] as? [String: Any]) ?? data
            completion(UserGamification(from: profilePayload))
        }
    }
    
    func fetchLeaderboard(completion: @escaping ([UserGamification]) -> Void) {
        functions.httpsCallable("getLeaderboard").call { result, error in
            guard error == nil,
                  let data = result?.data as? [String: Any],
                  let playersData = data["players"] as? [[String: Any]] else {
                completion([]); return
            }
            let players = playersData.compactMap { UserGamification(from: $0) }
            completion(players)
        }
    }
    
    func submitRideRating(rideId: String, rating: Int, comment: String,
                         completion: @escaping (SubmitRideRatingResult) -> Void) {
        let payload: [String: Any] = [
            "rideId": rideId,
            "rating": rating,
            "comment": comment
        ]
        functions.httpsCallable("submitRideRatingWithReward").call(payload) { result, error in
            if let error = error {
                completion(
                    SubmitRideRatingResult(
                        success: false,
                        pointsAwarded: 0,
                        newLevel: nil,
                        newTotalPoints: nil,
                        badgeUnlocked: nil,
                        message: error.localizedDescription
                    )
                )
                return
            }

            guard let data = result?.data as? [String: Any] else {
                completion(.failure)
                return
            }

            let badge: Badge? = {
                guard let badgeData = data["badgeUnlocked"] as? [String: Any] else {
                    return nil
                }
                return Badge(from: badgeData)
            }()

            completion(
                SubmitRideRatingResult(
                    success: (data["success"] as? Bool) ?? true,
                    pointsAwarded: data["pointsAwarded"] as? Int ?? 0,
                    newLevel: data["newLevel"] as? Int,
                    newTotalPoints: data["newTotalPoints"] as? Int,
                    badgeUnlocked: badge,
                    message: data["message"] as? String
                )
            )
        }
    }
}

