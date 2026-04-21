import FirebaseFirestore

final class FirestoreService {

    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User

    func loadUser(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(false); return }
            UserSession.shared.name = data["name"] as? String
            UserSession.shared.role = data["role"] as? String
            UserSession.shared.email = data["email"] as? String
            completion(true)
        }
    }

    func loadUserAnalytics(userId: String, completion: @escaping (String?) -> Void) {
        db.collection("user_analytics").document(userId).getDocument { snapshot, _ in
            completion(snapshot?.data()?["favoriteZone"] as? String)
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
