import SwiftUI

struct CreateRideView: View {
    @StateObject private var viewModel = CreateRideViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToRequests = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    formFields
                }
                .padding(.vertical, 24)
            }
            .background(Color.backgroundApp)
            .navigationBarHidden(true)
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .navigationDestination(isPresented: $navigateToRequests) {
                if let rideId = viewModel.createdRideId {
                    DriverRequestsView(rideId: rideId)
                }
            }
            .onChange(of: viewModel.createdRideId) { _, rideId in
                if rideId != nil { navigateToRequests = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Text("Create a Ride")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.textPrimary)
                Text("Share your route with the university community")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Form

    private var formFields: some View {
        VStack(spacing: 16) {

            // Origin
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.primaryBrand)
                TextField("Origin (e.g. Chapinero)", text: $viewModel.origin)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)
            }
            .inputStyle()

            // Destination
            HStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .foregroundColor(.green)
                TextField("Destination (e.g. Campus Norte)", text: $viewModel.destination)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)
            }
            .inputStyle()

            // Zone
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .foregroundColor(.placeholderMuted)
                TextField("Zone (e.g. Norte, Sur, Centro)", text: $viewModel.zone)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)
            }
            .inputStyle()

            // Departure time
            VStack(alignment: .leading, spacing: 6) {
                Text("Departure Time")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                DatePicker("",
                           selection: $viewModel.departureTime,
                           in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 52)
                    .background(Color.surfaceCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                    .cornerRadius(12)
            }

            // Seats
            VStack(alignment: .leading, spacing: 6) {
                Text("Available Seats")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .foregroundColor(.placeholderMuted)
                    Stepper("\(viewModel.seatsAvailable) seats",
                            value: $viewModel.seatsAvailable, in: 1...8)
                        .font(.custom("Poppins-Regular", size: 14))
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                .cornerRadius(12)
            }

            // Create button
            Button { viewModel.createRide() } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Ride")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.isValid ? Color.primaryBrand : Color.primaryBrand.opacity(0.4))
                .cornerRadius(12)
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
}
