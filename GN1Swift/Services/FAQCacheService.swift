import Foundation

// MARK: - Model

struct FAQItem: Codable, Identifiable {
    var id: String
    var question: String
    var answer: String
    var category: String
}

// MARK: - Cache

// NSCache for FAQ items — TTL 10 minutes
final class FAQCacheService {
    static let shared = FAQCacheService()

    private let cache = NSCache<NSString, NSArray>()
    private var timestamp: Date?
    private let ttl: TimeInterval = 600 // 10 minutes
    private let key = "faq_all" as NSString

    private init() {
        cache.countLimit = 50
    }

    func faqItems() -> [FAQItem]? {
        guard let ts = timestamp, Date().timeIntervalSince(ts) < ttl,
              let arr = cache.object(forKey: key) else {
            evict()
            return nil
        }
        return arr.compactMap { $0 as? NSDictionary }.map { d in
            FAQItem(
                id:       d["id"]       as? String ?? "",
                question: d["question"] as? String ?? "",
                answer:   d["answer"]   as? String ?? "",
                category: d["category"] as? String ?? "General"
            )
        }
    }

    func setFAQItems(_ items: [FAQItem]) {
        let arr = items.map { item -> NSDictionary in
            ["id": item.id, "question": item.question,
             "answer": item.answer, "category": item.category]
        } as NSArray
        cache.setObject(arr, forKey: key)
        timestamp = Date()
    }

    private func evict() {
        cache.removeObject(forKey: key)
        timestamp = nil
    }
}
