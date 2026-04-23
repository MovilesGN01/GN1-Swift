import SwiftUI

struct RegisterDetailsView: View {

    @Binding var isLoggedIn: Bool
    private let facade: AppFacadeType

    @State private var name = ""
    @State private var universityId = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    @State private var role = "passenger"
    @State private var selectedGender: Gender = .male
    @State private var carModel = ""
    @State private var plate = ""
    @State private var seats = ""

    @State private var acceptTerms = false
    @State private var isLoading = false

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private let institutionalDomain = "@uniandes.edu.co"

    init(isLoggedIn: Binding<Bool>, facade: AppFacadeType = AppFacade.shared) {
        self._isLoggedIn = isLoggedIn
        self.facade = facade
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // HEADER
                    VStack(spacing: 8) {
                        Text("STEP 1 OF 2")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.primaryBrand)

                        Text("Create Your Account")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.textPrimary)

                        Text("Join the university ridesharing community")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                    VStack(spacing: 16) {

                        nameField
                        universityIdField
                        emailField
                        passwordField
                        genderPicker
                        rolePicker

                        if role == "driver" || role == "both" {
                            carModelField
                            plateField
                            seatsField
                        }

                        Toggle(isOn: $acceptTerms) {
                            Text("I agree to the Terms of Service")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 10)

                        Button(action: registerUser) {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Next: Verify Identity")
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
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .background(Color.backgroundApp)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func registerUser() {
        if let validationError = validate() {
            errorMessage = validationError
            showErrorAlert = true
            return
        }

        isLoading = true
        facade.registerUser(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            role: role,
            gender: selectedGender,
            carModel: carModel,
            plate: plate,
            seats: Int(seats)
        ) { result in
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return "Name cannot be empty." }
        guard trimmedName.count <= 50 else { return "Name is too long (max 50 characters)." }
        let namePattern = #"^[\p{L}\p{M}\s'\-]+$"#
        guard trimmedName.range(of: namePattern, options: .regularExpression) != nil else {
            return "Name contains invalid characters."
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return "Email cannot be empty." }
        guard trimmedEmail.count <= 100 else { return "Email is too long." }
        let emailPattern = #"^[a-zA-Z0-9._%+\-]+@uniandes\.edu\.co$"#
        guard trimmedEmail.range(of: emailPattern, options: .regularExpression) != nil else {
            return "Use your institutional email (@uniandes.edu.co)."
        }

        guard !password.isEmpty else { return "Password cannot be empty." }
        guard password.count >= 6 else { return "Password must be at least 6 characters." }
        guard password.count <= 100 else { return "Password is too long." }

        if role == "driver" || role == "both" {
            guard !carModel.trimmingCharacters(in: .whitespaces).isEmpty else { return "Car model cannot be empty." }
            guard carModel.count <= 50 else { return "Car model is too long." }
            guard !plate.trimmingCharacters(in: .whitespaces).isEmpty else { return "Plate cannot be empty." }
            guard plate.count <= 10 else { return "Plate is too long (max 10 characters)." }
        }

        guard acceptTerms else { return "You must accept the Terms of Service." }

        return nil
    }
}

extension RegisterDetailsView {

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .foregroundColor(.placeholderMuted)

            TextField("Full Name", text: $name)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
                .onChange(of: name) { _, newValue in
                    if newValue.count > 50 { name = String(newValue.prefix(50)) }
                }
        }
        .inputStyle()
    }

    private var universityIdField: some View {
        HStack(spacing: 12) {
            Image(systemName: "number")
                .foregroundColor(.placeholderMuted)

            TextField("University ID", text: $universityId)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
                .keyboardType(.numberPad)
                .onChange(of: universityId) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue || newValue.count > 20 {
                        universityId = String(filtered.prefix(20))
                    }
                }
        }
        .inputStyle()
    }

    private var emailField: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope")
                .foregroundColor(.placeholderMuted)

            TextField("@uniandes.edu.co", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
                .onChange(of: email) { _, newValue in
                    if newValue.count > 100 { email = String(newValue.prefix(100)) }
                }
        }
        .inputStyle()
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.placeholderMuted)

            Group {
                if isPasswordVisible {
                    TextField("Password (min. 6 characters)", text: $password)
                } else {
                    SecureField("Password (min. 6 characters)", text: $password)
                }
            }
            .font(.custom("Poppins-Regular", size: 14))
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
        .inputStyle()
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gender")
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(.textSecondary)

            Picker("Gender", selection: $selectedGender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var rolePicker: some View {
        Picker("Role", selection: $role) {
            Text("Passenger").tag("passenger")
            Text("Driver").tag("driver")
            Text("Both").tag("both")
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var carModelField: some View {
        HStack(spacing: 12) {
            Image(systemName: "car")
                .foregroundColor(.placeholderMuted)

            TextField("Car Model", text: $carModel)
                .font(.custom("Poppins-Regular", size: 14))
                .onChange(of: carModel) { _, newValue in
                    if newValue.count > 50 { carModel = String(newValue.prefix(50)) }
                }
        }
        .inputStyle()
    }

    private var plateField: some View {
        HStack(spacing: 12) {
            Image(systemName: "number.square")
                .foregroundColor(.placeholderMuted)

            TextField("Plate", text: $plate)
                .font(.custom("Poppins-Regular", size: 14))
                .textInputAutocapitalization(.characters)
                .onChange(of: plate) { _, newValue in
                    if newValue.count > 10 { plate = String(newValue.prefix(10)) }
                }
        }
        .inputStyle()
    }

    private var seatsField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3")
                .foregroundColor(.placeholderMuted)

            TextField("Seats", text: $seats)
                .keyboardType(.numberPad)
                .font(.custom("Poppins-Regular", size: 14))
                .onChange(of: seats) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue { seats = filtered }
                }
        }
        .inputStyle()
    }
}
