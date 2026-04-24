import SwiftUI
import FirebaseCore

@main
struct GN1_SwiftApp: App {

    init() {
        FirebaseApp.configure()
        _ = PersistenceController.shared
    }

    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            if session.isRestoring {
                // Brief loading screen while UserSession is being rehydrated
                // from Firestore on a cold start with an existing session.
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                        Text("Restoring session…")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .task {
                    await session.restoreSessionIfNeeded()
                }
            } else if session.isLoggedIn {
                TabViewmain(isLoggedIn: $session.isLoggedIn)
            } else {
                LoginView(isLoggedIn: $session.isLoggedIn)
            }
        }
    }
}
