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
            // Try to load from cache for offline support
            if let cached = GamificationCacheManager.shared.loadCachedProfile() {
                self.gamification = cached
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Try to load from cache first (for immediate UI display)
        if let cached = GamificationCacheManager.shared.loadCachedProfile() {
            DispatchQueue.main.async {
                self.gamification = cached
            }
        }
        
        // Fetch fresh data from cloud
        facade.fetchGamificationProfile(userId: userId) { [weak self] profile in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let profile = profile {
                    self?.gamification = profile
                    GamificationCacheManager.shared.saveProfile(profile)
                } else {
                    // Use cached or create default
                    if let cached = GamificationCacheManager.shared.loadCachedProfile() {
                        self?.gamification = cached
                    } else {
                        self?.gamification = UserGamification(userId: userId)
                    }
                }
            }
        }
    }
    
    func loadTopPlayers() {
        isLoading = true
        
        // Try to load from cache first
        if let cached = GamificationCacheManager.shared.loadCachedLeaderboard() {
            DispatchQueue.main.async {
                self.topPlayers = cached
            }
        }
        
        // Fetch fresh data
        facade.fetchLeaderboard { [weak self] players in
            DispatchQueue.main.async {
                self?.isLoading = false
                if !players.isEmpty {
                    self?.topPlayers = players
                    GamificationCacheManager.shared.saveLeaderboard(players)
                } else {
                    // Use cached if fresh fetch failed
                    if let cached = GamificationCacheManager.shared.loadCachedLeaderboard() {
                        self?.topPlayers = cached
                    }
                }
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
