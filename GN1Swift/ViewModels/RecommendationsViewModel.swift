import Foundation
import Combine
import FirebaseAuth

class RecommendationsViewModel: ObservableObject {
    @Published var recommendedRides: [Ride] = []
    @Published var isLoading = false

    func loadRecommendations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        recommendedRides = []

        // Step 1: refresh analytics so the recommendedRides array is up to date
        CloudFunctionsService.shared.updateUserAnalytics { [weak self] in
            // Step 2: read the ride IDs from user_analytics and fetch each ride
            FirestoreService.shared.fetchRecommendedRides(userId: userId) { rides in
                DispatchQueue.main.async {
                    print("[Recommendations] received: \(rides.count)")
                    for r in rides {
                        print("[Recommendations] id:\(r.id) status:'\(r.status)' \(r.origin)→\(r.destination)")
                    }
                    // Show everything except rides that are definitively over
                    self?.recommendedRides = rides.filter {
                        $0.status != "completed" && $0.status != "in_progress"
                    }
                    self?.isLoading = false
                }
            }
        }
    }
}
