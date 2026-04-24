import Foundation
import Combine
import FirebaseAuth

class GamificationViewModel: ObservableObject {
    @Published var gamification: UserGamification?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var topPlayers: [UserGamification] = []
    @Published var recentAchievement: (badge: Badge, points: Int)? = nil
    
    private let facade: AppFacadeType
    
    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
    }
    
    func loadGamificationProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        facade.fetchGamificationProfile(userId: userId) { [weak self] profile in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let profile = profile {
                    self?.gamification = profile
                } else {
                    // Initialize default gamification if not exists
                    self?.gamification = UserGamification(userId: userId)
                }
            }
        }
    }
    
    func loadTopPlayers() {
        isLoading = true
        facade.fetchLeaderboard { [weak self] players in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.topPlayers = players
            }
        }
    }
    
    func refreshStreakStatus() {
        guard let gamification = gamification else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let lastActivityDate = gamification.streakInfo.lastActivityDate else {
            return
        }
        
        let daysSinceActivity = calendar.dateComponents([.day], from: lastActivityDate, to: now).day ?? 0
        
        if daysSinceActivity > 1 {
            // Streak broken
            var updated = gamification
            updated.streakInfo.currentStreak = 0
            self.gamification = updated
        }
    }
    
    func showAchievement(_ badge: Badge, points: Int) {
        recentAchievement = (badge: badge, points: points)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.recentAchievement = nil
        }
    }
}
