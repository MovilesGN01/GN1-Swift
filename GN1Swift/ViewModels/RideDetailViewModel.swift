import Foundation
import Combine

class RideDetailViewModel: ObservableObject {
    @Published var isRequesting = false
    @Published var requestSuccess = false
    @Published var alreadyRequested = false
    @Published var errorMessage: String?
    @Published var driverGamification: UserGamification?
    @Published var isLoadingGamification = false
    @Published var driverGender: String?

    let ride: Ride
    private let facade: AppFacadeType

    init(ride: Ride, facade: AppFacadeType = AppFacade.shared) {
        self.ride = ride
        self.facade = facade
    }

    func checkExistingRequest() {
        guard let userId = UserSession.shared.userId else { return }
        facade.hasExistingRequest(rideId: ride.id, passengerId: userId) { [weak self] exists in
            DispatchQueue.main.async {
                if exists { self?.alreadyRequested = true }
            }
        }
    }

    func loadDriverGender() {
        facade.fetchDriverGender(driverId: ride.driverId) { [weak self] gender in
            DispatchQueue.main.async {
                self?.driverGender = gender
            }
        }
    }

    func requestRide() {
        isRequesting = true
        facade.requestRide(rideId: ride.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isRequesting = false
                switch result {
                case .success:
                    self?.requestSuccess = true
                case .alreadyRequested:
                    self?.alreadyRequested = true
                    self?.errorMessage = "You already requested this ride."
                case .failure:
                    self?.errorMessage = "Failed to reserve ride. Please try again."
                }
            }
        }
    }

    func loadDriverGamification() {
        isLoadingGamification = true
        facade.fetchGamificationProfile(userId: ride.driverId) { [weak self] profile in
            DispatchQueue.main.async {
                self?.isLoadingGamification = false
                self?.driverGamification = profile
            }
        }
    }
}
