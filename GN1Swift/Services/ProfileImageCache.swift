import UIKit

// Network image cache — mirrors the architecture of KingFisher/SDWebImage.
// Layer 1: NSCache<NSString, UIImage>  (in-memory, instant)
// Layer 2: URLSession download          (network, on cache miss)
//
// NSCache configuration:
//   countLimit      = 20        → evicts least-recently-used when full
//   totalCostLimit  = 10 MB     → evicts when memory budget exceeded
//   cost per image  = w × h × 4 → estimated RGBA byte footprint
final class ProfileImageCache {
    static let shared = ProfileImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit     = 20
        cache.totalCostLimit = 10 * 1024 * 1024   // 10 MB
    }

    // MARK: - Load (cache-first, then network)

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let key = urlString as NSString

        // In-memory cache hit — returns instantly on calling thread
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil); return
        }

        // Background download via URLSession
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Store with per-image memory cost so NSCache can manage budget
            let cost = Int(image.size.width * image.size.height * 4)
            self?.cache.setObject(image, forKey: key, cost: cost)

            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    // MARK: - Evict

    func removeImage(forKey urlString: String) {
        cache.removeObject(forKey: urlString as NSString)
    }
}
