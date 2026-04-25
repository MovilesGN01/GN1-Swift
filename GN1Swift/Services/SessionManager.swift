import Foundation
import Combine
import FirebaseAuth

/// Single source of truth for login state and session restoration.
///
/// Persists two values to UserDefaults:
///   - `session_logged_in`  (Bool)   — whether the user is authenticated
///   - `session_user_id`    (String) — the Firebase UID, used to reload the profile on launch
///
/// On every cold start where the user was previously logged in, `restoreSessionIfNeeded()`
/// fetches the full user profile from Firestore and populates `UserSession.shared`,
/// so name, role, gender, etc. are available before any view appears.
final class SessionManager: ObservableObject {

    private static let loginKey  = "session_logged_in"
    private static let userIdKey = "session_user_id"

    // MARK: - Published State

    /// Controls root navigation. Backed by UserDefaults — survives restarts.
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: Self.loginKey)

            if isLoggedIn {
                // Auth.auth().currentUser is guaranteed non-nil right after a
                // successful Firebase sign-in, which always precedes this setter.
                if let uid = Auth.auth().currentUser?.uid {
                    UserDefaults.standard.set(uid, forKey: Self.userIdKey)
                }
            } else {
                // Logout — wipe stored identity
                UserDefaults.standard.removeObject(forKey: Self.userIdKey)
            }
        }
    }

    /// True only during the brief window at app launch when we are rehydrating
    /// UserSession from Firestore. The root view shows a spinner during this time.
    @Published private(set) var isRestoring: Bool

    // MARK: - Init

    init() {
        let hasLocalFlag    = UserDefaults.standard.bool(forKey: Self.loginKey)
        let hasFirebaseUser = Auth.auth().currentUser != nil
        let shouldLogin     = hasLocalFlag && hasFirebaseUser

        isLoggedIn  = shouldLogin
        // Only block the UI with a spinner when there actually is a session to restore.
        isRestoring = shouldLogin
    }

    // MARK: - Session Restoration

    /// Fetches the full user profile from Firestore and populates `UserSession.shared`.
    /// Must be called once on app launch when `isLoggedIn == true`.
    /// Safe to call from a `@MainActor` context (e.g. `.task` in SwiftUI).
    @MainActor
    func restoreSessionIfNeeded() async {
        defer { isRestoring = false }           // always clear spinner when done

        guard isLoggedIn,
              let userId = UserDefaults.standard.string(forKey: Self.userIdKey)
        else { return }

        // Populate userId immediately from UserDefaults so ViewModels that check
        // UserSession.shared.userId on first appear don't see nil while Firestore loads.
        UserSession.shared.userId = userId

        // Bridge the existing callback-based service to async/await.
        // FirestoreService.loadUser populates UserSession.shared (name, role, gender…)
        // exactly as it does during a normal login — no duplicate logic.
        await withCheckedContinuation { continuation in
            FirestoreService.shared.loadUser(userId: userId) { _ in
                continuation.resume()
            }
        }
    }
}
