import Foundation
import FirebaseAnalytics

// Sprint 4 Analytics Service
// Answers: "What percentage of support requests and wallet interactions happen
// while users are offline, and how does eventual connectivity improve feature usability?"
// All events flow: Firebase Analytics → BigQuery Export → Looker Studio

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Wallet Events

    func walletOpened(userId: String, online: Bool) {
        Analytics.logEvent("wallet_opened", parameters: [
            "userId": userId,
            "online": online ? "true" : "false",
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func walletLoadedFromCache(cacheHit: Bool, loadTime: Double) {
        Analytics.logEvent("wallet_loaded_from_cache", parameters: [
            "cacheHit": cacheHit ? "true" : "false",
            "loadTime": loadTime
        ])
    }

    func walletTransactionViewed(online: Bool) {
        Analytics.logEvent("wallet_transaction_viewed", parameters: [
            "online": online ? "true" : "false"
        ])
    }

    func walletOfflineSnapshotLoaded(snapshotExists: Bool) {
        Analytics.logEvent("wallet_offline_snapshot_loaded", parameters: [
            "snapshotExists": snapshotExists ? "true" : "false"
        ])
    }

    // MARK: - Help Center Events

    func helpOpened(online: Bool) {
        Analytics.logEvent("help_opened", parameters: [
            "online": online ? "true" : "false"
        ])
    }

    func ticketCreated(createdOffline: Bool, online: Bool) {
        Analytics.logEvent("ticket_created", parameters: [
            "createdOffline": createdOffline ? "true" : "false",
            "online": online ? "true" : "false"
        ])
    }

    func pendingTicketSynced(syncSuccess: Bool, syncTime: Double) {
        Analytics.logEvent("pending_ticket_synced", parameters: [
            "syncSuccess": syncSuccess ? "true" : "false",
            "syncTime": syncTime
        ])
    }

    func faqLoadedFromCache(cacheHit: Bool) {
        Analytics.logEvent("faq_loaded_cache", parameters: [
            "cacheHit": cacheHit ? "true" : "false"
        ])
    }
}
