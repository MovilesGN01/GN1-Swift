import SwiftUI

struct LoginView: View {

    @Binding var isLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showInvalidEmailAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var goToRegister = false

    private let institutionalDomain = "@uniandes.edu.co"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    logoSection

                    VStack(spacing: 16) {
                        emailField
                        passwordField

                        HStack {
                            Spacer()
                            Button("Forgot your password?") {
                            }
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.primaryBrand)
                        }
                        .padding(.top, -4)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 16) {
                        Button(action: login) {
                            Text("Sign In")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primaryBrand)
                                .cornerRadius(12)
                        }

                        HStack {
                            Rectangle()
                                .fill(Color.borderLine)
                                .frame(height: 1)

                            Text("  o  ")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.placeholderMuted)

                            Rectangle()
                                .fill(Color.borderLine)
                                .frame(height: 1)
                        }

                        Button {
                            goToRegister = true
                        } label: {
                            Text("Sign Up")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.primaryBrand)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primaryBrand, lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
                .padding(.vertical, 24)
            }
            .background(Color.backgroundApp)
            .navigationDestination(isPresented: $goToRegister) {
                RegisterDetailsView(isLoggedIn: $isLoggedIn)
            }
            .alert("Invalid email", isPresented: $showInvalidEmailAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You must use your institutional email @uniandes.edu.co")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 20)

            Text("UniRide")
                .font(.custom("Poppins-Bold", size: 36))
                .foregroundColor(.primaryBrand)

            Text("Your university ridesharing community")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 48)
        }
        .padding(.horizontal, 24)
    }

    private var emailField: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope")
                .foregroundColor(.placeholderMuted)

            TextField("@uniandes.edu.co", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderLine, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.placeholderMuted)

            Group {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.custom("Poppins-Regular", size: 14))
            .foregroundColor(.textPrimary)

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(.placeholderMuted)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderLine, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // LOGIN → Firebase Auth
    private func login() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard normalizedEmail.hasSuffix(institutionalDomain) else {
            showInvalidEmailAlert = true
            return
        }

        AuthService.shared.login(email: normalizedEmail, password: password) { userId in
            
            DispatchQueue.main.async {
                
                if let userId = userId {
                    
                    // Guardar sesión básica
                    UserSession.shared.userId = userId
                    UserSession.shared.email = normalizedEmail
                    
                    // Cargar datos del usuario desde Firestore
                    FirestoreService.shared.loadUser(userId: userId) { success in
                        
                        DispatchQueue.main.async {
                            if success {
                                isLoggedIn = true
                            } else {
                                errorMessage = "Could not load user profile"
                                showErrorAlert = true
                            }
                        }
                    }
                    
                } else {
                    errorMessage = "Login failed"
                    showErrorAlert = true
                }
            }
        }
    }
    
}
