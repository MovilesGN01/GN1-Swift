import Foundation
import Combine

class HomeViewModel: ObservableObject {

    @Published var stats: CachedUserStats?
    @Published var nextRide: CachedNextRide?
    @Published var recentHistory: [CachedHistoryItem] = []
    @Published var isOffline = false
    @Published var isLoading = true

    private let cache = HomeLocalCache.shared
    private let facade: AppFacadeType

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }

    // MARK: - Load
    // Called on every tab appearance — file cache prevents blank flash.

    func load() {
        // 1. Serve cached file data immediately so UI is never blank
        stats = cache.loadStats()
        nextRide = cache.loadNextRide()
        recentHistory = cache.loadHistory()

        guard let userId = UserSession.shared.userId else {
            isLoading = false
            return
        }

        isLoading = true

        let group = DispatchGroup()
        var onlineSuccesses = 0

        // Local vars captured by group.notify to combine into stats
        var gamification: UserGamification?
        var totalRides = 0

        // ── Gamification profile (points + level) ─────────────────────────
        // Lives in `userGamification/{userId}`, NOT user_analytics.
        group.enter()
        facade.fetchGamificationProfile(userId: userId) { profile in
            DispatchQueue.main.async {
                defer { group.leave() }
                if let p = profile {
                    onlineSuccesses += 1
                    gamification = p
                }
            }
        }

        // ── Next active ride ───────────────────────────────────────────────
        group.enter()
        facade.fetchPassengerRequests(passengerId: userId) { [weak self] requests in
            guard let self else { group.leave(); return }
            onlineSuccesses += 1

            let req = requests.first(where: { $0.status == "accepted" })
                   ?? requests.first(where: { $0.status == "pending" })

            guard let req else {
                DispatchQueue.main.async {
                    self.nextRide = nil
                    self.cache.saveNextRide(nil)
                    group.leave()
                }
                return
            }

            FirestoreService.shared.fetchRide(rideId: req.rideId) { ride in
                DispatchQueue.main.async {
                    defer { group.leave() }
                    guard let ride else { return }
                    let cached = CachedNextRide(
                        rideId: ride.id,
                        origin: ride.origin,
                        destination: ride.destination,
                        departureTime: ride.departureTime,
                        driverName: ride.driverName,
                        status: req.status
                    )
                    self.nextRide = cached
                    self.cache.saveNextRide(cached)
                }
            }
        }

        // ── Ride history (also provides totalRides count) ─────────────────
        group.enter()
        facade.fetchRideHistory(passengerId: userId) { [weak self] history in
            DispatchQueue.main.async {
                defer { group.leave() }
                guard let self else { return }
                onlineSuccesses += 1
                totalRides = history.count
                let items = Array(history.prefix(3).map {
                    CachedHistoryItem(
                        origin: $0.origin,
                        destination: $0.destination,
                        completedAt: $0.completedAt
                    )
                })
                self.recentHistory = items
                self.cache.saveHistory(items)
            }
        }

        // ── Combine and finish ─────────────────────────────────────────────
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }

            if let gam = gamification {
                let s = CachedUserStats(
                    points: gam.points,
                    level: gam.level,
                    totalRides: totalRides,
                    favoriteZone: ""
                )
                self.stats = s
                self.cache.saveStats(s)
            }

            // Gamification uses a Cloud Function (HTTPS callable) — it requires
            // a real network connection, unlike direct Firestore queries which
            // Firestore SDK can serve from its own internal cache.
            // If gamification fetch returned nil → no network available.
            self.isOffline = gamification == nil
            self.isLoading = false
        }
    }
}
