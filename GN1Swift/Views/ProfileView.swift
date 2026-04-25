import SwiftUI
import FirebaseAuth

struct ProfileView: View {

    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack {
            Spacer()

            Button(action: logout) {
                Text("Log Out")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color.backgroundApp)
        .navigationTitle("Profile")
    }

    private func logout() {
        try? Auth.auth().signOut()
        isLoggedIn = false
    }
}
