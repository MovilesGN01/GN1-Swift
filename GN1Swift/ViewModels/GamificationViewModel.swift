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
    private var authListener: AuthStateDidChangeListenerHandle?

    init(facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self, user != nil else { return }
            Task { [weak self] in
                guard let self else { return }
                async let profileLoad: Void = self.fetchAndCacheProfile()
                async let leaderboardLoad: Void = self.fetchAndCacheLeaderboard()
                _ = await (profileLoad, leaderboardLoad)
            }
        }
    }

    deinit {
        if let handle = authListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }


    func loadGamificationProfile() {
        Task { [weak self] in await self?.fetchAndCacheProfile() }
    }

    func loadTopPlayers() {
        Task { [weak self] in await self?.fetchAndCacheLeaderboard() }
    }

    // MARK: - Core async: perfil

    private func fetchAndCacheProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            if let diskCached = GamificationCacheManager.shared.loadCachedProfile() {
                await MainActor.run { self.gamification = diskCached }
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        // L1
        if let memCached = GamificationMemoryCache.shared.getProfile(forKey: userId) {
            await MainActor.run { self.gamification = memCached }
        } else if let diskCached = GamificationCacheManager.shared.loadCachedProfile() {
            await MainActor.run { self.gamification = diskCached }
        }

        guard !GamificationCacheInvalidation.shared.isProfileCacheValid() else {
            await MainActor.run { self.isLoading = false }
            return
        }

        let profile: UserGamification? = await withCheckedContinuation { continuation in
            facade.fetchGamificationProfile(userId: userId) { continuation.resume(returning: $0) }
        }

        if let profile {
            let hasChanged: Bool = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(
                        returning: GamificationCacheInvalidation.shared.hasProfileChanged(profile)
                    )
                }
            }

            await MainActor.run {
                if hasChanged { self.gamification = profile }
                GamificationMemoryCache.shared.setProfile(profile, forKey: userId)
                GamificationCacheManager.shared.saveProfile(profile)
                GamificationCacheInvalidation.shared.saveProfileMetadata(profile)
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.gamification = GamificationMemoryCache.shared.getProfile(forKey: userId)
                    ?? GamificationCacheManager.shared.loadCachedProfile()
                    ?? UserGamification(userId: userId)
                self.isLoading = false
            }
        }
    }

    // MARK: - Core async: leaderboard

    private func fetchAndCacheLeaderboard() async {
        await MainActor.run { self.isLoading = true }

        if let memCached = GamificationMemoryCache.shared.getLeaderboard() {
            await MainActor.run { self.topPlayers = memCached }
        } else if let diskCached = GamificationCacheManager.shared.loadCachedLeaderboard() {
            await MainActor.run { self.topPlayers = diskCached }
        }

        guard !GamificationCacheInvalidation.shared.isLeaderboardCacheValid() else {
            await MainActor.run { self.isLoading = false }
            return
        }

        let players: [UserGamification] = await withCheckedContinuation { continuation in
            facade.fetchLeaderboard { continuation.resume(returning: $0) }
        }

        if !players.isEmpty {
            let hasChanged: Bool = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(
                        returning: GamificationCacheInvalidation.shared.hasLeaderboardChanged(players)
                    )
                }
            }

            await MainActor.run {
                if hasChanged { self.topPlayers = players }
                GamificationMemoryCache.shared.setLeaderboard(players)
                GamificationCacheManager.shared.saveLeaderboard(players)
                GamificationCacheInvalidation.shared.saveLeaderboardMetadata(players)
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.topPlayers = GamificationMemoryCache.shared.getLeaderboard()
                    ?? GamificationCacheManager.shared.loadCachedLeaderboard()
                    ?? []
                self.isLoading = false
            }
        }
    }

    // MARK: - Streak

    func refreshStreakStatus() {
        guard let gamification else { return }
        guard let lastActivityDate = gamification.streakInfo.lastActivityDate else { return }
        let daysSinceActivity = Calendar.current
            .dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        if daysSinceActivity > 1 {
            var updated = gamification
            updated.streakInfo.currentStreak = 0
            self.gamification = updated
        }
    }

    // MARK: - Achievement

    func showAchievement(_ badge: Badge, points: Int) {
        recentAchievement = (badge: badge, points: points)
        // Task.sleep reemplaza DispatchQueue.main.asyncAfter
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run { self?.recentAchievement = nil }
        }
    }
}
