import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class RecommendationsViewModel: ObservableObject {
    @Published var recommendedRides: [Ride] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func loadRecommendations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        db.collection("user_analytics").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self = self,
                  let rideIds = snapshot?.data()?["recommendedRides"] as? [String],
                  !rideIds.isEmpty else {
                DispatchQueue.main.async {
                    self?.recommendedRides = []
                    self?.isLoading = false
                }
                return
            }
            self.fetchRides(rideIds: rideIds)
        }
    }

    private func fetchRides(rideIds: [String]) {
        var rides: [Ride] = []
        let group = DispatchGroup()

        for rideId in rideIds {
            group.enter()
            db.collection("rides").document(rideId).getDocument { snap, _ in
                if let snap = snap, let data = snap.data() {
                    var d = data
                    d["id"] = snap.documentID
                    rides.append(Ride(from: d))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.recommendedRides = rides
            self?.isLoading = false
        }
    }
}
