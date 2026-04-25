import Foundation
import Combine
import FirebaseAuth

class RecommendationsViewModel: ObservableObject {
    @Published var recommendedRides: [Ride] = []
    @Published var isLoading = false

    private let cache = CacheService.shared
    private let cacheKey = "recommendations"

    func loadRecommendations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Serve from cache immediately if available — skip the network round-trip
        if let cached = cache.rides(forKey: cacheKey) {
            recommendedRides = cached
            return
        }

        isLoading = true
        recommendedRides = []

        // Step 1: refresh analytics so the recommendedRides array is up to date
        CloudFunctionsService.shared.updateUserAnalytics { [weak self] in
            guard let self else { return }
            // Step 2: read the ride IDs from user_analytics and fetch each ride
            FirestoreService.shared.fetchRecommendedRides(userId: userId) { rides in
                DispatchQueue.main.async {
                    print("[Recommendations] received: \(rides.count)")
                    for r in rides {
                        print("[Recommendations] id:\(r.id) status:'\(r.status)' \(r.origin)→\(r.destination)")
                    }
                    // Show everything except rides that are definitively over
                    let filtered = rides.filter {
                        $0.status != "completed" && $0.status != "in_progress"
                    }
                    self.cache.setRides(filtered, forKey: self.cacheKey)
                    self.recommendedRides = filtered
                    self.isLoading = false
                }
            }
        }
    }

    func refreshRecommendations() {
        cache.invalidate(forKey: cacheKey)
        loadRecommendations()
    }
}
