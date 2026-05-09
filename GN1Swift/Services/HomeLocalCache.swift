import Foundation

// MARK: - Codable models for file-based cache

struct CachedUserStats: Codable {
    let points: Int
    let level: Int
    let totalRides: Int
    let favoriteZone: String
}

struct CachedNextRide: Codable {
    let rideId: String
    let origin: String
    let destination: String
    let departureTime: Date
    let driverName: String
    let status: String  // "pending" | "accepted"
}

struct CachedHistoryItem: Codable, Identifiable {
    var id: String { "\(origin)-\(destination)-\(completedAt.timeIntervalSince1970)" }
    let origin: String
    let destination: String
    let completedAt: Date
}

// MARK: - File-based cache (FileManager + JSON)

/// Persists lightweight home screen data as JSON files in the app's Documents directory.
/// This is a distinct persistence layer from CoreData (structured ride data) and
/// UserDefaults (session tokens), used for small analytics snapshots.
final class HomeLocalCache {
    static let shared = HomeLocalCache()
    private init() {}

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    private func url(for fileName: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    // MARK: - User Stats

    func saveStats(_ stats: CachedUserStats) {
        write(stats, to: "home_user_stats.json")
    }

    func loadStats() -> CachedUserStats? {
        read(CachedUserStats.self, from: "home_user_stats.json")
    }

    // MARK: - Next Ride

    func saveNextRide(_ ride: CachedNextRide?) {
        if let ride {
            write(ride, to: "home_next_ride.json")
        } else {
            if let url = url(for: "home_next_ride.json") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    func loadNextRide() -> CachedNextRide? {
        read(CachedNextRide.self, from: "home_next_ride.json")
    }

    // MARK: - Recent History

    func saveHistory(_ items: [CachedHistoryItem]) {
        write(items, to: "home_recent_history.json")
    }

    func loadHistory() -> [CachedHistoryItem] {
        read([CachedHistoryItem].self, from: "home_recent_history.json") ?? []
    }

    // MARK: - Generic read / write

    private func write<T: Encodable>(_ value: T, to fileName: String) {
        guard let url = url(for: fileName),
              let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func read<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        guard let url = url(for: fileName),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
