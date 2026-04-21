import Foundation
import Combine

/// Handles all data for Passenger Mode:
/// available marketplace rides (excluding own) + recommended rides.
/// Pair with MyRequestsViewModel for the "My Requests" section.
class PassengerRidesViewModel: ObservableObject {

    @Published var allRides: [Ride] = []
    @Published var filteredRides: [Ride] = []
    @Published var recommendedRides: [Ride] = []
    @Published var zones: [String] = ["All"]
    @Published var isLoading = false

    @Published var selectedZone: String = "All" { didSet { filterRides() } }
    @Published var minRating: Double = 0.0 { didSet { filterRides() } }
    @Published var minSeats: Int = 1 { didSet { filterRides() } }

    private let facade: AppFacadeType
    private var currentUserId: String { UserSession.shared.userId ?? "" }

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    func loadRides() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        facade.fetchAllAvailableRides { [weak self] rides in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Filter out the signed-in driver's own rides from the marketplace.
                let marketplace = rides.filter { $0.driverId != self.currentUserId }
                self.allRides = marketplace
                self.extractZones(from: marketplace)
                self.filterRides()
                group.leave()
            }
        }

        group.enter()
        facade.fetchRecommendedRides { [weak self] rides in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let filtered = rides.filter { $0.driverId != self.currentUserId }
                self.recommendedRides = RideRankingService.rank(filtered)
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    func filterRides() {
        var result = allRides
        if selectedZone != "All" {
            result = result.filter { $0.zone == selectedZone }
        }
        if minRating > 0 {
            result = result.filter { $0.driverRating >= minRating }
        }
        result = result.filter { $0.seatsAvailable >= minSeats }
        filteredRides = RideRankingService.rank(result)
    }

    func applyFilters() { filterRides() }

    private func extractZones(from rides: [Ride]) {
        let sorted = Set(rides.compactMap { $0.zone.isEmpty ? nil : $0.zone }).sorted()
        zones = ["All"] + sorted
    }
}
