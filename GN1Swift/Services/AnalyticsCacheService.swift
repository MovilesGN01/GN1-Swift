import Foundation

// MARK: - Cached wrapper objects (NSObject required by NSCache)

final class CachedZoneAnalytics: NSObject {
    let zones: [String: Int]
    let mostDemandedZone: String
    let timestamp: Date

    init(zones: [String: Int], mostDemandedZone: String) {
        self.zones = zones
        self.mostDemandedZone = mostDemandedZone
        self.timestamp = Date()
    }
}

final class CachedPeakHoursAnalytics: NSObject {
    let hours: [Int: Int]
    let morningPeak: Int?
    let eveningPeak: Int?
    let timestamp: Date

    init(hours: [Int: Int], morningPeak: Int?, eveningPeak: Int?) {
        self.hours = hours
        self.morningPeak = morningPeak
        self.eveningPeak = eveningPeak
        self.timestamp = Date()
    }
}

// MARK: - Cache service with TTL

final class AnalyticsCacheService {
    static let shared = AnalyticsCacheService()
    private init() {}

    private let ttl: TimeInterval = 300  // 5 minutes

    private let zonesCache     = NSCache<NSString, CachedZoneAnalytics>()
    private let peakHoursCache = NSCache<NSString, CachedPeakHoursAnalytics>()

    private let zonesKey: NSString     = "topZones"
    private let peakHoursKey: NSString = "peakHours"

    // MARK: - Zone Analytics

    func zoneAnalytics() -> CachedZoneAnalytics? {
        guard let cached = zonesCache.object(forKey: zonesKey),
              Date().timeIntervalSince(cached.timestamp) < ttl else { return nil }
        return cached
    }

    func setZoneAnalytics(zones: [String: Int], mostDemandedZone: String) {
        let obj = CachedZoneAnalytics(zones: zones, mostDemandedZone: mostDemandedZone)
        zonesCache.setObject(obj, forKey: zonesKey)
    }

    // MARK: - Peak Hours Analytics

    func peakHoursAnalytics() -> CachedPeakHoursAnalytics? {
        guard let cached = peakHoursCache.object(forKey: peakHoursKey),
              Date().timeIntervalSince(cached.timestamp) < ttl else { return nil }
        return cached
    }

    func setPeakHoursAnalytics(hours: [Int: Int], morningPeak: Int?, eveningPeak: Int?) {
        let obj = CachedPeakHoursAnalytics(hours: hours, morningPeak: morningPeak, eveningPeak: eveningPeak)
        peakHoursCache.setObject(obj, forKey: peakHoursKey)
    }

    func invalidateAll() {
        zonesCache.removeAllObjects()
        peakHoursCache.removeAllObjects()
    }
}
