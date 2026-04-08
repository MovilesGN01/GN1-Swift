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
    @State private var carModel = ""
    @State private var plate = ""
    @State private var seats = ""
    
    @State private var acceptTerms = false
    
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
                            Text("Next: Verify Identity")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primaryBrand)
                                .cornerRadius(12)
                        }
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
        
        if !acceptTerms {
            errorMessage = "You must accept the terms"
            showErrorAlert = true
            return
        }
        
        if !email.hasSuffix(institutionalDomain) {
            errorMessage = "Use institutional email"
            showErrorAlert = true
            return
        }
        
        facade.registerUser(
            name: name,
            email: email,
            password: password,
            role: role,
            carModel: carModel,
            plate: plate,
            seats: Int(seats)
        ) { result in
            DispatchQueue.main.async {
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
}

extension RegisterDetailsView {
    
    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .foregroundColor(.placeholderMuted)
            
            TextField("Full Name", text: $name)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
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
        }
        .inputStyle()
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
            .font(.custom("Poppins-Regular", size: 14))
            
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(.placeholderMuted)
            }
        }
        .inputStyle()
    }
    
    private var carModelField: some View {
        HStack(spacing: 12) {
            Image(systemName: "car")
                .foregroundColor(.placeholderMuted)
            
            TextField("Car Model", text: $carModel)
                .font(.custom("Poppins-Regular", size: 14))
        }
        .inputStyle()
    }
    
    private var plateField: some View {
        HStack(spacing: 12) {
            Image(systemName: "number.square")
                .foregroundColor(.placeholderMuted)
            
            TextField("Plate", text: $plate)
                .font(.custom("Poppins-Regular", size: 14))
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
        }
        .inputStyle()
    }
    
    private var rolePicker: some View {
        Picker("Role", selection: $role) {
            Text("Passenger").tag("passenger")
            Text("Driver").tag("driver")
            Text("Both").tag("both")
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}


