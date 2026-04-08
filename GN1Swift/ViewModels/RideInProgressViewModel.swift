import Foundation
import Combine

class RideInProgressViewModel: ObservableObject {

    @Published var acceptedPassengers: [RideRequest] = []
    @Published var isFinishing = false
    @Published var errorMessage: String?

    let ride: Ride

    private let facade: AppFacadeType
    private var stopListening: (() -> Void)?

    init(ride: Ride, facade: AppFacadeType = AppFacade.shared) {
        self.ride = ride
        self.facade = facade
    }

    func startListening() {
        stopListening = facade.listenToAcceptedPassengers(rideId: ride.id) { [weak self] passengers in
            DispatchQueue.main.async {
                self?.acceptedPassengers = passengers
            }
        }
    }

    func stopListeningNow() {
        stopListening?()
    }

    deinit { stopListening?() }

    // MARK: - Actions

    /// Full finish sequence:
    /// 1. finishRide CF  → marks ride completed, creates rideHistory, marks requests completed
    /// 2. updateUserAnalytics CF → refreshes user_analytics (favoriteZone, favoriteHour, ridesPerMonth)
    /// 3. Calls completion so the view navigates home
    func finishRide(completion: @escaping () -> Void) {
        isFinishing = true
        facade.finishRide(rideId: ride.id) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                DispatchQueue.main.async {
                    self.isFinishing = false
                    self.errorMessage = "Failed to finish ride. Please try again."
                }
                return
            }
            // Write status directly so passenger listener always picks it up
            self.facade.markRideRequestsCompleted(rideId: self.ride.id)
            // Update analytics so getRideRecommendations has fresh data
            self.facade.updateUserAnalytics {
                DispatchQueue.main.async {
                    self.isFinishing = false
                    completion()
                }
            }
        }
    }
}
