import Foundation

final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteRoute] = []
    private let dataSource = FavoriteRouteLocalDataSource()

    func load() {
        favorites = dataSource.fetchAll()
    }

    func save(origin: String, destination: String, zone: String) {
        guard !origin.trimmingCharacters(in: .whitespaces).isEmpty,
              !destination.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        dataSource.save(origin: origin, destination: destination, zone: zone) { [weak self] in
            self?.load()
        }
    }

    func delete(id: String) {
        favorites.removeAll { $0.id == id }
        dataSource.delete(id: id)
    }

    func apply(_ favorite: FavoriteRoute, to viewModel: CreateRideViewModel) {
        viewModel.originText = favorite.origin
        viewModel.destinationText = favorite.destination
        viewModel.zone = favorite.zone
        dataSource.incrementUseCount(id: favorite.id) { [weak self] in
            self?.load()
        }
    }
}
