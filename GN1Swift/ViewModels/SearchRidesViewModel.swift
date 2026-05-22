import Foundation
import Combine

final class SearchRidesViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Ride] = []
    @Published var isFiltering = false

    private let allRides: [Ride]
    private var cancellables = Set<AnyCancellable>()

    init(rides: [Ride]) {
        self.allRides = rides
        self.results = rides

        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in self?.filterInBackground(query: q) }
            .store(in: &cancellables)
    }

    // MARK: - Background filtering

    private func filterInBackground(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else {
            results = allRides
            isFiltering = false
            return
        }
        isFiltering = true
        let rides = allRides
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let filtered = rides.filter { ride in
                ride.origin.lowercased().contains(q)
                    || ride.destination.lowercased().contains(q)
                    || ride.zone.lowercased().contains(q)
                    || ride.driverName.lowercased().contains(q)
            }
            DispatchQueue.main.async {
                self?.results = filtered
                self?.isFiltering = false
            }
        }
    }
}
