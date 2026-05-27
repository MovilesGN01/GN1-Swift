import Foundation

// MARK: - Model

struct FAQItem: Codable, Identifiable {
    var id: String
    var question: String
    var answer: String
    var category: String
}

// MARK: - TTL Cache  (NO NSCache — pure in-memory struct with timestamp)
//
// Decision: NSCache was deliberately avoided here to show a DIFFERENT caching
// strategy from Wallet (which uses NSCache). This cache uses a plain array +
// timestamp checked on every read.
//
// TTL: 30 minutes — FAQ content changes infrequently; a 30-min window reduces
// Firebase reads without showing stale critical data.
//
// On expiry: returns nil → caller reloads from Firestore and calls setFAQItems().

final class FAQCacheService {
    static let shared = FAQCacheService()
    private init() {}

    private var cachedItems: [FAQItem] = []
    private var cachedAt:    Date?
    private let ttl: TimeInterval = 1800 // 30 minutes

    var isExpired: Bool {
        guard let ts = cachedAt else { return true }
        return Date().timeIntervalSince(ts) >= ttl
    }

    var minutesUntilExpiry: Int {
        guard let ts = cachedAt, !isExpired else { return 0 }
        let remaining = ttl - Date().timeIntervalSince(ts)
        return max(0, Int(remaining / 60))
    }

    func faqItems() -> [FAQItem]? {
        guard !isExpired, !cachedItems.isEmpty else {
            cachedItems = []
            cachedAt    = nil
            return nil
        }
        return cachedItems
    }

    func setFAQItems(_ items: [FAQItem]) {
        cachedItems = items
        cachedAt    = Date()
    }

    func invalidate() {
        cachedItems = []
        cachedAt    = nil
    }
}
