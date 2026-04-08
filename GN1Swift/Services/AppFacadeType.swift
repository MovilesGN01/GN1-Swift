import Foundation

protocol AppFacadeType {
    func signIn(email: String, password: String, completion: @escaping (AuthFlowResult) -> Void)
    func fetchAllAvailableRides(completion: @escaping ([Ride]) -> Void)
    func fetchRecommendedRides(completion: @escaping ([Ride]) -> Void)
    func requestRide(rideId: String, completion: @escaping (RequestRideResult) -> Void)
    func listenToDriverRides(driverId: String, completion: @escaping ([Ride]) -> Void) -> (() -> Void)
    func listenToDriverRequests(driverId: String, completion: @escaping ([RideRequest]) -> Void) -> (() -> Void)
    func listenToRideRequests(rideId: String, completion: @escaping ([RideRequest]) -> Void) -> (() -> Void)
    func acceptRide(requestId: String, completion: @escaping (Bool) -> Void)
    func rejectRide(requestId: String, completion: @escaping (Bool) -> Void)
    func updateRequestStatus(requestId: String, status: String)
    func fetchUserName(userId: String, completion: @escaping (String?) -> Void)
    func registerUser(
        name: String,
        email: String,
        password: String,
        role: String,
        carModel: String,
        plate: String,
        seats: Int?,
        completion: @escaping (AuthFlowResult) -> Void
    )
}
