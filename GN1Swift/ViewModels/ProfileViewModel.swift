import UIKit
import Combine
import FirebaseFirestore
import FirebaseStorage

final class ProfileViewModel: ObservableObject {

    // MARK: - User Data
    @Published var userName: String  = ""
    @Published var userEmail: String = ""
    @Published var userRating: Double = 0.0
    @Published var userRole: String  = ""
    @Published var profileImage: UIImage? = nil   // loaded via ProfileImageCache

    // MARK: - BQ2: Cache vs Firebase Performance
    @Published var cachedLoadTime: Double = 0.0
    @Published var networkLoadTime: Double = 0.0
    @Published var improvementPercentage: Double = 0.0

    // MARK: - State
    @Published var isOffline: Bool  = false
    @Published var isLoading: Bool  = false
    @Published var dataSource: String = ""   // which cache layer was hit

    // MARK: - Services
    private let db             = Firestore.firestore()
    private let localDataSource = ProfileLocalDataSource()     // CoreData
    private let fileStorage    = ProfileFileStorage.shared     // JSON file
    private let defaults       = UserDefaults.standard

    // UserDefaults keys (Preferences / Key-Value strategy)
    private let keyName      = "profile_userName"
    private let keyEmail     = "profile_userEmail"
    private let keyRating    = "profile_userRating"
    private let keyTimestamp = "profile_lastFetchTimestamp"

    // =========================================================================
    // MARK: - STEPS 1-3  Cache Load  (DispatchQueue — Input/Output thread)
    // =========================================================================
    // Threading strategy A:
    //   DispatchQueue.global(qos: .background) → I/O operations
    //   DispatchQueue.main.async              → UI update
    // =========================================================================

    func loadProfile() {
        guard let userId = UserSession.shared.userId else { return }
        isLoading = true

        let cacheStart = Date()

        // ── I/O Thread: read all local layers ──────────────────────────────
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            var hit: String      = ""
            var cachedDict: NSDictionary?

            // Layer 1 — NSCache (in-memory, fastest, lives for current session)
            if let mem = ProfileCacheService.shared.profile(forKey: userId) {
                cachedDict = mem
                hit = "NSCache (in-memory)"
            }

            // Layer 2 — CoreData (relational DB, persisted across launches)
            if cachedDict == nil,
               let saved = self.localDataSource.loadProfile(userId: userId) {
                cachedDict = ["name": saved.name, "email": saved.email,
                              "rating": saved.rating, "role": saved.role] as NSDictionary
                hit = "CoreData (local DB)"
            }

            // Layer 3 — UserDefaults (key-value store, persisted across launches)
            if cachedDict == nil, let local = self.loadUserFromLocal() {
                cachedDict = local as NSDictionary
                hit = "UserDefaults (key-value)"
            }

            // Layer 4 — Local JSON file (Documents directory, persisted across launches)
            if cachedDict == nil, let file = self.fileStorage.load() {
                cachedDict = ["name": file.name, "email": file.email,
                              "rating": file.rating, "role": file.role] as NSDictionary
                hit = "Local File (JSON)"
            }

            let cacheMs = Date().timeIntervalSince(cacheStart) * 1000

            // ── Main Thread: update UI with whatever was found in cache ─────
            DispatchQueue.main.async {
                self.cachedLoadTime = cacheMs
                self.dataSource     = hit.isEmpty ? "No local data" : hit

                if let data = cachedDict {
                    self.userName   = data["name"]   as? String ?? ""
                    self.userEmail  = data["email"]  as? String ?? ""
                    self.userRating = data["rating"] as? Double ?? 0.0
                    self.userRole   = data["role"]   as? String ?? ""
                }

                // Load local photo if no Firebase URL was cached yet
                self.loadLocalProfilePhoto()

                // Always refresh from Firebase concurrently (Task)
                self.fetchFromFirebaseAsync(userId: userId)
            }
        }
    }

    // =========================================================================
    // MARK: - STEPS 4-8  Firebase Fetch  (Task + async/await)
    // =========================================================================
    // Threading strategy B:
    //   Task { }             → runs concurrently on Swift cooperative thread pool
    //   await MainActor.run  → equivalent to DispatchQueue.main for async context
    // =========================================================================

    private func fetchFromFirebaseAsync(userId: String) {
        let networkStart = Date()

        // ── Task: concurrent execution, does NOT block the main thread ──────
        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Bridge Firestore callback → async/await via continuation
                let snapshot: DocumentSnapshot = try await withCheckedThrowingContinuation { cont in
                    self.db.collection("users").document(userId).getDocument { snap, err in
                        if let err  { cont.resume(throwing: err);      return }
                        if let snap { cont.resume(returning: snap);     return }
                        cont.resume(throwing: ProfileFetchError.noSnapshot)
                    }
                }

                let networkMs = Date().timeIntervalSince(networkStart) * 1000

                guard let data = snapshot.data() else {
                    await MainActor.run {
                        self.isLoading = false
                        self.networkLoadTime = networkMs
                        self.computeImprovement()
                    }
                    return
                }

                // Parse Firestore fields
                let name     = data["name"]            as? String ?? ""
                let email    = data["email"]           as? String ?? ""
                let rating   = data["driverRating"]    as? Double
                             ?? data["reputationScore"] as? Double ?? 0.0
                let role     = data["role"]            as? String ?? ""
                let photoURL = data["photoURL"]        as? String ?? ""

                // ── Still on Task thread (all caches are thread-safe) ─────
                // Update Layer 1: NSCache
                ProfileCacheService.shared.setProfile(
                    ["name": name, "email": email,
                     "rating": rating, "role": role] as NSDictionary,
                    forKey: userId
                )
                // Update Layer 2: CoreData (uses its own background context internally)
                self.localDataSource.saveProfile(userId: userId, name: name,
                                                  email: email, rating: rating, role: role)
                // Update Layer 4: JSON file
                self.fileStorage.save(name: name, email: email, rating: rating, role: role)

                // Load profile image if URL provided (ProfileImageCache strategy)
                if !photoURL.isEmpty {
                    ProfileImageCache.shared.loadImage(from: photoURL) { [weak self] img in
                        self?.profileImage = img  // already dispatched to main by cache
                    }
                }

                // ── MainActor: UI update ─────────────────────────────────
                await MainActor.run {
                    self.isOffline       = false
                    self.isLoading       = false
                    self.dataSource      = "Firebase Firestore (network)"
                    self.userName        = name
                    self.userEmail       = email
                    self.userRating      = rating
                    self.userRole        = role
                    self.networkLoadTime = networkMs
                    self.saveUserToLocal(name: name, email: email, rating: rating)  // Layer 3
                    self.computeImprovement()
                }

            } catch {
                let networkMs = Date().timeIntervalSince(networkStart) * 1000
                await MainActor.run {
                    print("[ProfileVM] Firebase error:", error.localizedDescription)
                    self.isOffline       = true
                    self.isLoading       = false
                    self.networkLoadTime = networkMs
                    self.computeImprovement()
                }
            }
        }
    }

    // =========================================================================
    // MARK: - Profile Photo  (Firebase Storage upload + local cache)
    // =========================================================================

    private var localPhotoURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("profile_photo.jpg")
    }

    // Called when the user picks a new photo from the library
    func updateProfilePhoto(_ image: UIImage) {
        // 1. Show in UI immediately (optimistic update)
        profileImage = image

        // 2. Persist locally (Documents/profile_photo.jpg)
        if let data = image.jpegData(compressionQuality: 0.85),
           let url = localPhotoURL {
            try? data.write(to: url, options: .atomic)
        }

        // 3. Upload to Firebase Storage → save URL to Firestore
        guard let userId = UserSession.shared.userId,
              let data = image.jpegData(compressionQuality: 0.85) else { return }

        let storageRef = Storage.storage()
            .reference()
            .child("profile_images/\(userId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(data, metadata: metadata) { [weak self] _, error in
            if let error = error {
                print("[ProfileVM] Storage upload error:", error.localizedDescription)
                return
            }
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else { return }
                // 4. Save photoURL to Firestore so other devices pick it up
                Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData(["photoURL": downloadURL.absoluteString]) { err in
                        if let err { print("[ProfileVM] Firestore photoURL update error:", err) }
                    }
                // 5. Cache the URL in ProfileImageCache
                ProfileImageCache.shared.loadImage(from: downloadURL.absoluteString) { [weak self] img in
                    self?.profileImage = img ?? image
                }
            }
        }
    }

    // Loads photo saved locally from a previous session (fallback when no URL in Firestore)
    func loadLocalProfilePhoto() {
        guard profileImage == nil, let url = localPhotoURL,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.profileImage = image }
    }

    // =========================================================================
    // MARK: - Local Storage: UserDefaults  (Layer 3 — Preferences strategy)
    // =========================================================================

    func saveUserToLocal(name: String, email: String, rating: Double) {
        defaults.set(name,   forKey: keyName)
        defaults.set(email,  forKey: keyEmail)
        defaults.set(rating, forKey: keyRating)
        defaults.set(Date().timeIntervalSince1970, forKey: keyTimestamp)
    }

    func loadUserFromLocal() -> [String: Any]? {
        guard let name = defaults.string(forKey: keyName), !name.isEmpty else { return nil }
        return [
            "name":   name,
            "email":  defaults.string(forKey: keyEmail) ?? "",
            "rating": defaults.double(forKey: keyRating),
            "role":   ""
        ]
    }

    // =========================================================================
    // MARK: - BQ2 Computation
    // =========================================================================

    private func computeImprovement() {
        guard networkLoadTime > 0 else { return }
        improvementPercentage = ((networkLoadTime - cachedLoadTime) / networkLoadTime) * 100
    }
}

// MARK: - Internal Error

private enum ProfileFetchError: Error {
    case noSnapshot
}
