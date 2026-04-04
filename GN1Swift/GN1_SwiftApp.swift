import SwiftUI
import FirebaseCore

@main
struct GN1_SwiftApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabViewmain()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
