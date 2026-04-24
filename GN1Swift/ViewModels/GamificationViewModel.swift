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
            // Try to load from disk cache for offline support
            if let diskCached = GamificationCacheManager.shared.loadCachedProfile() {
                self.gamification = diskCached
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // L1: Try memory cache first (instant)
        if let memCached = GamificationMemoryCache.shared.getProfile(forKey: userId) {
            DispatchQueue.main.async {
                self.gamification = memCached
            }
        } else if let diskCached = GamificationCacheManager.shared.loadCachedProfile() {
            DispatchQueue.main.async {
                self.gamification = diskCached
            }
        }
        
        // Check if cache is still valid (smart invalidation)
        let cacheValid = GamificationCacheInvalidation.shared.isProfileCacheValid()
        
        if cacheValid {
            // Cache is fresh enough, no need to fetch
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            return
        }
        
        // Fetch fresh data from cloud
        facade.fetchGamificationProfile(userId: userId) { [weak self] profile in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let profile = profile {
                    // Check if profile actually changed before updating
                    let hasChanged = GamificationCacheInvalidation.shared.hasProfileChanged(profile)
                    
                    if hasChanged {
                        self?.gamification = profile
                    }
                    
                    // Cache in all levels
                    GamificationMemoryCache.shared.setProfile(profile, forKey: userId)
                    GamificationCacheManager.shared.saveProfile(profile)
                    GamificationCacheInvalidation.shared.saveProfileMetadata(profile)
                } else {
                    // Use cached or create default
                    if let memCached = GamificationMemoryCache.shared.getProfile(forKey: userId) {
                        self?.gamification = memCached
                    } else if let diskCached = GamificationCacheManager.shared.loadCachedProfile() {
                        self?.gamification = diskCached
                    } else {
                        self?.gamification = UserGamification(userId: userId)
                    }
                }
            }
        }
    }
    
    func loadTopPlayers() {
        isLoading = true
        
        // L1: Try memory cache first (instant)
        if let memCached = GamificationMemoryCache.shared.getLeaderboard() {
            DispatchQueue.main.async {
                self.topPlayers = memCached
            }
        } else if let diskCached = GamificationCacheManager.shared.loadCachedLeaderboard() {
            DispatchQueue.main.async {
                self.topPlayers = diskCached
            }
        }
        
        // Check if cache is still valid (smart invalidation)
        let cacheValid = GamificationCacheInvalidation.shared.isLeaderboardCacheValid()
        
        if cacheValid {
            // Cache is fresh enough, no need to fetch
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            return
        }
        
        // Fetch fresh data
        facade.fetchLeaderboard { [weak self] players in
            DispatchQueue.main.async {
                self?.isLoading = false
                if !players.isEmpty {
                    // Check if leaderboard actually changed before updating
                    let hasChanged = GamificationCacheInvalidation.shared.hasLeaderboardChanged(players)
                    
                    if hasChanged {
                        self?.topPlayers = players
                    }
                    
                    // Cache in all levels
                    GamificationMemoryCache.shared.setLeaderboard(players)
                    GamificationCacheManager.shared.saveLeaderboard(players)
                    GamificationCacheInvalidation.shared.saveLeaderboardMetadata(players)
                } else {
                    // Use cached if fresh fetch failed
                    if let memCached = GamificationMemoryCache.shared.getLeaderboard() {
                        self?.topPlayers = memCached
                    } else if let diskCached = GamificationCacheManager.shared.loadCachedLeaderboard() {
                        self?.topPlayers = diskCached
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
