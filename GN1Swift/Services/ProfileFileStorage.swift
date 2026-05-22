import Foundation

// Local Files strategy — saves the profile as a JSON file in the app's Documents directory.
// This is the 4th and final local layer in the cache chain, below UserDefaults.
final class ProfileFileStorage {
    static let shared = ProfileFileStorage()

    private let fileName = "profile_cache.json"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    // MARK: - Write

    func save(name: String, email: String, rating: Double, role: String) {
        guard let url = fileURL else { return }
        let dict: [String: Any] = [
            "name":    name,
            "email":   email,
            "rating":  rating,
            "role":    role,
            "savedAt": Date().timeIntervalSince1970
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict,
                                                     options: .prettyPrinted) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Read

    func load() -> (name: String, email: String, rating: Double, role: String)? {
        guard let url    = fileURL,
              let data   = try? Data(contentsOf: url),
              let dict   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name   = dict["name"] as? String,
              !name.isEmpty else { return nil }
        return (
            name:   name,
            email:  dict["email"]  as? String ?? "",
            rating: dict["rating"] as? Double ?? 0.0,
            role:   dict["role"]   as? String ?? ""
        )
    }
}
