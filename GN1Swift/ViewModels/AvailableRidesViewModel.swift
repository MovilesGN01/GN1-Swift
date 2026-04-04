import Foundation
import Combine

class AvailableRidesViewModel: ObservableObject {

    @Published var allRides: [Ride] = []
    @Published var recommendedRides: [Ride] = []
    @Published var filteredRides: [Ride] = []
    @Published var zones: [String] = ["All"]
    @Published var isLoading = false

    @Published var selectedZone: String = "All" {
        didSet { filterRides() }
    }
    @Published var minRating: Double = 0.0 {
        didSet { filterRides() }
    }
    @Published var minSeats: Int = 1 {
        didSet { filterRides() }
    }

    func loadRides() {
        isLoading = true

        let group = DispatchGroup()

        let currentUserId = UserSession.shared.userId ?? ""

        group.enter()
        CloudFunctionsService.shared.getAllAvailableRides { [weak self] rides in
            DispatchQueue.main.async {
                // Never show the current user's own rides in the marketplace.
                let marketplace = rides.filter { $0.driverId != currentUserId }
                self?.allRides = marketplace
                self?.extractZones(from: marketplace)
                self?.filterRides()
                group.leave()
            }
        }

        group.enter()
        CloudFunctionsService.shared.getRecommendedRides { [weak self] rides in
            DispatchQueue.main.async {
                self?.recommendedRides = rides.filter { $0.driverId != currentUserId }
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

        filteredRides = result
    }

    // Kept for explicit "Search" button compatibility
    func applyFilters() {
        filterRides()
    }

    private func extractZones(from rides: [Ride]) {
        let sorted = Set(rides.compactMap { $0.zone.isEmpty ? nil : $0.zone }).sorted()
        zones = ["All"] + sorted
    }
}
