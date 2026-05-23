import Foundation
import Combine

final class AnalyticsDashboardViewModel: ObservableObject {

    @Published var zoneAnalytics: CachedZoneAnalytics?
    @Published var peakHoursAnalytics: CachedPeakHoursAnalytics?
    @Published var isLoading = false
    @Published var isOffline = false
    @Published var cacheHit = false
    @Published var lastRefreshed: Date?

    private let cache = AnalyticsCacheService.shared

    // MARK: - Load

    func load() {
        let cachedZones = cache.zoneAnalytics()
        let cachedPeak  = cache.peakHoursAnalytics()

        // TTL still valid — serve instantly without any network call
        if let z = cachedZones, let p = cachedPeak {
            zoneAnalytics = z
            peakHoursAnalytics = p
            cacheHit = true
            lastRefreshed = z.timestamp
            return
        }

        isLoading = true
        cacheHit  = false

        // Fire both CF refresh + Firestore reads concurrently with async let
        Task { [weak self] in
            guard let self else { return }
            async let zonesTask: Void = self.refreshZones()
            async let peakTask: Void  = self.refreshPeakHours()
            _ = await (zonesTask, peakTask)
            await MainActor.run { self.isLoading = false }
        }
    }

    func forceRefresh() {
        cache.invalidateAll()
        isLoading = true
        cacheHit  = false
        Task { [weak self] in
            guard let self else { return }
            async let zonesTask: Void = self.refreshZones()
            async let peakTask: Void  = self.refreshPeakHours()
            _ = await (zonesTask, peakTask)
            await MainActor.run { self.isLoading = false }
        }
    }

    // MARK: - Private helpers

    private func refreshZones() async {
        await withCheckedContinuation { continuation in
            CloudFunctionsService.shared.calculateTopZones {
                FirestoreService.shared.fetchZoneAnalytics { [weak self] result in
                    guard let self else { continuation.resume(); return }
                    DispatchQueue.main.async {
                        if let r = result {
                            self.cache.setZoneAnalytics(zones: r.zones,
                                                        mostDemandedZone: r.mostDemandedZone)
                            self.zoneAnalytics  = self.cache.zoneAnalytics()
                            self.lastRefreshed  = Date()
                            self.isOffline      = false
                        } else {
                            self.isOffline = true
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func refreshPeakHours() async {
        await withCheckedContinuation { continuation in
            CloudFunctionsService.shared.calculatePeakHours {
                FirestoreService.shared.fetchPeakHoursAnalytics { [weak self] result in
                    guard let self else { continuation.resume(); return }
                    DispatchQueue.main.async {
                        if let r = result {
                            self.cache.setPeakHoursAnalytics(hours: r.hours,
                                                              morningPeak: r.morningPeak,
                                                              eveningPeak: r.eveningPeak)
                            self.peakHoursAnalytics = self.cache.peakHoursAnalytics()
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
}
