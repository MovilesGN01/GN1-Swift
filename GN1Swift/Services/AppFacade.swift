import Foundation

final class AppFacade: AppFacadeType {
    static let shared = AppFacade()

    private let authService: AuthService
    private let firestoreService: FirestoreService
    private let cloudFunctionsService: CloudFunctionsService
    private let locationService: LocationService
    private let session: UserSession

    init(
        authService: AuthService = .shared,
        firestoreService: FirestoreService = .shared,
        cloudFunctionsService: CloudFunctionsService = .shared,
        locationService: LocationService = .shared,
        session: UserSession = .shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.cloudFunctionsService = cloudFunctionsService
        self.locationService = locationService
        self.session = session
    }

    func signIn(email: String, password: String, completion: @escaping (AuthFlowResult) -> Void) {
        authService.login(email: email, password: password) { [weak self] userId in
            guard let self = self, let userId = userId else {
                completion(.failure(message: "Login failed"))
                return
            }

            self.session.userId = userId
            self.session.email = email

            self.firestoreService.loadUser(userId: userId) { success in
                if success {
                    completion(.success)
                } else {
                    completion(.failure(message: "Could not load user profile"))
                }
            }
        }
    }

    func fetchAllAvailableRides(completion: @escaping ([Ride]) -> Void) {
        cloudFunctionsService.getAllAvailableRides(completion: completion)
    }

    func fetchRecommendedRides(completion: @escaping ([Ride]) -> Void) {
        cloudFunctionsService.getRecommendedRides(completion: completion)
    }

    func requestRide(rideId: String, completion: @escaping (RequestRideResult) -> Void) {
        cloudFunctionsService.requestRide(rideId: rideId, completion: completion)
    }

    func createRide(
        origin: String,
        destination: String,
        zone: String,
        departureTime: Date,
        seatsAvailable: Int,
        completion: @escaping (String?) -> Void
    ) {
        cloudFunctionsService.createRide(
            origin: origin,
            destination: destination,
            zone: zone,
            departureTime: departureTime,
            seatsAvailable: seatsAvailable,
            completion: completion
        )
    }

    func hasExistingRequest(rideId: String, passengerId: String, completion: @escaping (Bool) -> Void) {
        firestoreService.hasExistingRequest(rideId: rideId, passengerId: passengerId, completion: completion)
    }

    func listenToDriverRides(driverId: String, completion: @escaping ([Ride]) -> Void) -> (() -> Void) {
        firestoreService.listenToDriverRides(driverId: driverId, completion: completion)
    }

    func listenToDriverRequests(driverId: String,
                                completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        firestoreService.listenToDriverRequests(driverId: driverId, completion: completion)
    }

    func listenToRideRequests(rideId: String,
                              completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        firestoreService.listenToRideRequests(rideId: rideId, completion: completion)
    }

    func listenToAcceptedPassengers(rideId: String,
                                    completion: @escaping ([RideRequest]) -> Void) -> (() -> Void) {
        firestoreService.listenToAcceptedPassengers(rideId: rideId, completion: completion)
    }

    func acceptRide(requestId: String, completion: @escaping (Bool) -> Void) {
        cloudFunctionsService.acceptRide(requestId: requestId, completion: completion)
    }

    func rejectRide(requestId: String, completion: @escaping (Bool) -> Void) {
        cloudFunctionsService.rejectRide(requestId: requestId, completion: completion)
    }

    func finishRide(rideId: String, completion: @escaping (Bool) -> Void) {
        cloudFunctionsService.finishRide(rideId: rideId, completion: completion)
    }

    func updateUserAnalytics(completion: @escaping () -> Void) {
        cloudFunctionsService.updateUserAnalytics(completion: completion)
    }

    func updateRequestStatus(requestId: String, status: String) {
        firestoreService.updateRequestStatus(requestId: requestId, status: status)
    }

    func markRideRequestsCompleted(rideId: String) {
        firestoreService.markRideRequestsCompleted(rideId: rideId)
    }

    func fetchUserName(userId: String, completion: @escaping (String?) -> Void) {
        firestoreService.fetchUserName(userId: userId, completion: completion)
    }

    func requestLocationPermissionAndStart() {
        locationService.requestPermissionAndStart()
    }

    func registerUser(
        name: String,
        email: String,
        password: String,
        role: String,
        carModel: String,
        plate: String,
        seats: Int?,
        completion: @escaping (AuthFlowResult) -> Void
    ) {
        authService.register(email: email, password: password) { [weak self] userId in
            guard let self = self, let userId = userId else {
                completion(.failure(message: "Error creating account"))
                return
            }

            self.session.userId = userId
            self.session.email = email
            self.session.name = name
            self.session.role = role
            self.session.carModel = carModel
            self.session.plate = plate
            self.session.seats = seats

            self.cloudFunctionsService.createUserDocument { success in
                if success {
                    // Initialize gamification profile for new user
                    self.fetchGamificationProfile(userId: userId) { _ in
                        completion(.success)
                    }
                } else {
                    completion(.failure(message: "Error creating user profile"))
                }
            }
        }
    }  
  
    func fetchGamificationProfile(userId: String, completion: @escaping (UserGamification?) -> Void) {
        cloudFunctionsService.fetchGamificationProfile(userId: userId, completion: completion)
    }
    
    func fetchLeaderboard(completion: @escaping ([UserGamification]) -> Void) {
        cloudFunctionsService.fetchLeaderboard(completion: completion)
    }
    
    func submitRideRating(rideId: String, rating: Int, comment: String,
                         completion: @escaping (SubmitRideRatingResult) -> Void) {
        cloudFunctionsService.submitRideRating(rideId: rideId, rating: rating, comment: comment, completion: completion)
    }
}
