import SwiftUI

struct LoginView: View {

    @Binding var isLoggedIn: Bool
    private let facade: AppFacadeType

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var goToRegister = false

    private let institutionalDomain = "@uniandes.edu.co"

    init(isLoggedIn: Binding<Bool>, facade: AppFacadeType = AppFacade.shared) {
        self._isLoggedIn = isLoggedIn
        self.facade = facade
    }

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
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.primaryBrand)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)

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
                        .disabled(isLoading)
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
                .onChange(of: email) { _, newValue in
                    if newValue.count > 100 { email = String(newValue.prefix(100)) }
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
            .onChange(of: password) { _, newValue in
                if newValue.count > 100 { password = String(newValue.prefix(100)) }
            }

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

    // MARK: - Login

    private func login() {
        if let validationError = validate() {
            errorMessage = validationError
            showErrorAlert = true
            return
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        isLoading = true
        facade.signIn(email: normalizedEmail, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    isLoggedIn = true
                case .failure(let message):
                    errorMessage = message
                    showErrorAlert = true
                }
            }
        }
    }

    private func validate() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return "Email cannot be empty." }
        guard trimmedEmail.count <= 100 else { return "Email is too long." }
        let emailPattern = #"^[a-zA-Z0-9._%+\-]+@uniandes\.edu\.co$"#
        guard trimmedEmail.range(of: emailPattern, options: .regularExpression) != nil else {
            return "Use your institutional email (@uniandes.edu.co)."
        }

        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else { return "Password cannot be empty." }
        guard trimmedPassword.count >= 6 else { return "Password must be at least 6 characters." }

        return nil
    }
}
