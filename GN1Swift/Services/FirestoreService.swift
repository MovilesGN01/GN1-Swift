import FirebaseFirestore

final class FirestoreService {

    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User

    func loadUser(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(false); return }
            // Always set userId — critical for session restoration where the caller
            // (SessionManager) hasn't pre-populated UserSession.shared.userId.
            UserSession.shared.userId = userId
            UserSession.shared.name = data["name"] as? String
            UserSession.shared.role = data["role"] as? String
            UserSession.shared.email = data["email"] as? String
            if let genderRaw = data["gender"] as? String {
                UserSession.shared.gender = Gender(rawValue: genderRaw)
            }
            completion(true)
        }
    }

    func fetchDriverGender(driverId: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(driverId).getDocument { snapshot, _ in
            completion(snapshot?.data()?["gender"] as? String)
        }
    }

    func loadUserAnalytics(userId: String, completion: @escaping (String?) -> Void) {
        db.collection("user_analytics").document(userId).getDocument { snapshot, _ in
            completion(snapshot?.data()?["favoriteZone"] as? String)
        }
    }

    /// Fetches the full user_analytics document and maps it to a UserAnalytics struct.
    func fetchUserAnalyticsFull(userId: String, completion: @escaping (UserAnalytics?) -> Void) {
        db.collection("user_analytics").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(nil); return }
            var d = data
            d["userId"] = userId
            completion(UserAnalytics(from: d))
        }
    }

    /// Reads user_analytics/{userId}.recommendedRides (array of ride IDs),
    /// then fetches each ride from the rides collection in parallel.
    func fetchRecommendedRides(userId: String, completion: @escaping ([Ride]) -> Void) {
        db.collection("user_analytics").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self = self,
                  let rideIds = snapshot?.data()?["recommendedRides"] as? [String],
                  !rideIds.isEmpty else {
                completion([]); return
            }

            var rides: [Ride] = []
            let group = DispatchGroup()

            for rideId in rideIds {
                group.enter()
                self.db.collection("rides").document(rideId).getDocument { snap, _ in
                    if let snap = snap, let data = snap.data() {
                        var d = data
                        d["id"] = snap.documentID
                        rides.append(Ride(from: d))
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { completion(rides) }
        }
    }

    // MARK: - Weather

    func loadWeather(completion: @escaping (WeatherData?) -> Void) {
        db.collection("analytics_cache").document("weatherDemand").getDocument { snapshot, error in
            guard let data = snapshot?.data() else {
                print("Error loading weather:", error?.localizedDescription ?? "")
                completion(nil); return
            }
            let weather = data["weather"] as? String ?? ""
            let temperature = data["temperature"] as? Double ?? 0
            let demandLevel = data["demandLevel"] as? String ?? ""
            let demandMultiplier = data["demandMultiplier"] as? Double ?? 1
            completion(WeatherData(
                weather: weather,
                temperature: temperature,
                demandLevel: demandLevel,
                demandMultiplier: demandMultiplier,
                estimatedWaitTime: Int(10 * demandMultiplier)
            ))
        }
    }

    // MARK: - Rides

    func fetchRide(rideId: String, completion: @escaping (Ride?) -> Void) {
        db.collection("rides").document(rideId).getDocument { snapshot, _ in
            guard let snapshot = snapshot, let data = snapshot.data() else {
                completion(nil); return
            }
            var d = data
            d["id"] = snapshot.documentID
            completion(Ride(from: d))
        }
    }

    func updateRideStatus(rideId: String, status: String, completion: @escaping (Bool) -> Void) {
        db.collection("rides").document(rideId).updateData(["status": status]) { error in
            completion(error == nil)
        }
    }

    /// Directly sets a single rideRequest's status (fallback for when CF doesn't update it).
    func updateRequestStatus(requestId: String, status: String) {
        db.collection("rideRequests").document(requestId).updateData(["status": status]) { error in
            if let error = error {
                print("[Firestore] updateRequestStatus error:", error.localizedDescription)
            } else {
                print("[Firestore] Request \(requestId) → \(status)")
            }
        }
    }

    /// Marks ALL rideRequests for a given ride as "completed".
    func markRideRequestsCompleted(rideId: String) {
        db.collection("rideRequests")
            .whereField("rideId", isEqualTo: rideId)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    print("[Firestore] markRideRequestsCompleted: no docs for ride \(rideId)", error?.localizedDescription ?? "")
                    return
                }
                for doc in docs {
                    doc.reference.updateData(["status": "completed"]) { err in
                        if let err = err {
                            print("[Firestore] markRideRequestsCompleted error on \(doc.documentID):", err.localizedDescription)
                        } else {
                            print("[Firestore] Request \(doc.documentID) → completed")
                        }
                    }
                }
            }
    }

    /// One-shot check: does a non-rejected request exist for this ride + passenger?
    func hasExistingRequest(rideId: String, passengerId: String,
                            completion: @escaping (Bool) -> Void) {
        db.collection("rideRequests")
            .whereField("rideId", isEqualTo: rideId)
            .whereField("passengerId", isEqualTo: passengerId)
            .whereField("status", in: ["pending", "accepted"])
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                completion(!(snapshot?.isEmpty ?? true))
            }
    }

    // MARK: - Ride Requests (Realtime)

    /// Listen for requests on a specific ride (driver flow after CreateRide).
    /// Returns a stop-listening closure — call it from `onDisappear` or `deinit`.
    func listenToRideRequests(rideId: String,
                              completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        let listener = db.collection("rideRequests")
            .whereField("rideId", isEqualTo: rideId)
            .addSnapshotListener { snapshot, _ in
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(requests)
            }
        return { listener.remove() }
    }

    /// Real-time list of accepted passengers for a specific ride (used in RideInProgressView).
    func listenToAcceptedPassengers(rideId: String,
                                    completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        let listener = db.collection("rideRequests")
            .whereField("rideId", isEqualTo: rideId)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, _ in
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(requests)
            }
        return { listener.remove() }
    }

    /// Listen for all pending requests addressed to a driver.
    func listenToDriverRequests(driverId: String,
                                completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        let listener = db.collection("rideRequests")
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { snapshot, _ in
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(requests)
            }
        return { listener.remove() }
    }

    // MARK: - Ride History

    func createRideHistory(from ride: Ride,
                           passengerId: String,
                           driverRating: Double,
                           passengerRating: Double,
                           completion: @escaping (Bool) -> Void) {
        guard let driverId = UserSession.shared.userId else { completion(false); return }
        let data: [String: Any] = [
            "rideId": ride.id,
            "driverId": driverId,
            "passengerId": passengerId,
            "origin": ride.origin,
            "destination": ride.destination,
            "zone": ride.zone,
            "driverRating": driverRating,
            "passengerRating": passengerRating,
            "completedAt": Timestamp(date: Date())
        ]
        db.collection("rideHistory").addDocument(data: data) { error in
            completion(error == nil)
        }
    }

    /// Listen to all ride requests made by a specific passenger.
    func listenToPassengerRequests(passengerId: String,
                                   completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        let listener = db.collection("rideRequests")
            .whereField("passengerId", isEqualTo: passengerId)
            .addSnapshotListener { snapshot, _ in
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(requests)
            }
        return { listener.remove() }
    }

    /// Listen to all rides created by a specific driver.
    func listenToDriverRides(driverId: String,
                             completion: @escaping ([Ride]) -> Void) -> (() -> Void) {
        let listener = db.collection("rides")
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { snapshot, _ in
                let rides = snapshot?.documents.map { doc -> Ride in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return Ride(from: data)
                } ?? []
                completion(rides)
            }
        return { listener.remove() }
    }

    func fetchUserName(userId: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            completion(snapshot?.data()?["name"] as? String)
        }
    }

    // MARK: - Coordinates

    func updateRideCoordinates(rideId: String,
                               originLat: Double, originLng: Double,
                               destinationLat: Double, destinationLng: Double) {
        db.collection("rides").document(rideId).updateData([
            "originLat": originLat,
            "originLng": originLng,
            "destinationLat": destinationLat,
            "destinationLng": destinationLng
        ]) { error in
            if let error = error {
                print("[Firestore] updateRideCoordinates error:", error.localizedDescription)
            }
        }
    }

    func updateUserLocation(userId: String, latitude: Double, longitude: Double) {
        db.collection("users").document(userId).updateData([
            "lastLatitude": latitude,
            "lastLongitude": longitude
        ]) { error in
            if let error = error {
                print("[Firestore] updateUserLocation error:", error.localizedDescription)
            }
        }
    }

    // MARK: - Passenger One-Shot Fetches

    /// One-shot fetch of all active (pending/accepted) ride requests for a passenger.
    func fetchPassengerRequests(
        passengerId: String,
        completion: @escaping ([RideRequest]) -> Void
    ) {
        db.collection("rideRequests")
            .whereField("passengerId", isEqualTo: passengerId)
            .whereField("status", in: ["pending", "accepted"])
            .getDocuments { snapshot, _ in
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(requests)
            }
    }

    /// One-shot fetch of all completed rides for a passenger.
    func fetchRideHistory(
        passengerId: String,
        completion: @escaping ([RideHistory]) -> Void
    ) {
        db.collection("rideHistory")
            .whereField("passengerId", isEqualTo: passengerId)
            .getDocuments { snapshot, _ in
                let history = snapshot?.documents.map {
                    RideHistory(id: $0.documentID, from: $0.data())
                } ?? []
                completion(history)
            }
    }

    /// Online-first fetch of passenger requests — returns `.failure` on network error
    /// so callers can distinguish "offline" from "user has no requests".
    func fetchPassengerRequestsResult(
        passengerId: String,
        completion: @escaping (Result<[RideRequest], Error>) -> Void
    ) {
        db.collection("rideRequests")
            .whereField("passengerId", isEqualTo: passengerId)
            .whereField("status", in: ["pending", "accepted"])
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error)); return
                }
                let requests = snapshot?.documents.map {
                    RideRequest(id: $0.documentID, from: $0.data())
                } ?? []
                completion(.success(requests))
            }
    }

    /// Online-first fetch of ride history — returns `.failure` on network error.
    func fetchRideHistoryResult(
        passengerId: String,
        completion: @escaping (Result<[RideHistory], Error>) -> Void
    ) {
        db.collection("rideHistory")
            .whereField("passengerId", isEqualTo: passengerId)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error)); return
                }
                let history = snapshot?.documents.map {
                    RideHistory(id: $0.documentID, from: $0.data())
                } ?? []
                completion(.success(history))
            }
    }

    // MARK: - Ratings

    func saveRating(rideId: String, rating: Int, comment: String,
                    completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "rideId": rideId,
            "rating": rating,
            "comment": comment,
            "userId": UserSession.shared.userId ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        db.collection("ratings").addDocument(data: data) { error in
            completion(error == nil)
        }
    }
}
