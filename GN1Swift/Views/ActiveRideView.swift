import SwiftUI

struct ActiveRideView: View {
    @StateObject private var viewModel: ActiveRideViewModel
    @State private var navigateToComplete = false

    init(ride: Ride) {
        _viewModel = StateObject(wrappedValue: ActiveRideViewModel(ride: ride))
    }

    var body: some View {
        VStack(spacing: 0) {
            appBar
            ScrollView {
                VStack(spacing: 16) {
                    statusBanner
                    driverCard
                    routeCard
                    if viewModel.isDriver {
                        completeButton
                    }
                }
                .padding(16)
            }
        }
        .background(Color.backgroundApp)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToComplete) {
            CompleteRideView(ride: viewModel.ride)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - App Bar

    private var appBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Active Ride")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)
                Text(viewModel.isDriver ? "You are driving · tap Complete when done" : "Ride in progress")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Circle().fill(Color.green).frame(width: 10, height: 10)
            Text("In Progress")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(.green)
            Spacer()
            Text(viewModel.ride.departureTime.formatted(date: .omitted, time: .shortened))
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.green.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))
        .cornerRadius(12)
    }

    // MARK: - Driver Card

    private var driverCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.primaryBrand.opacity(0.12))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(viewModel.ride.driverName.prefix(1)))
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.primaryBrand)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.ride.driverName)
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 11))
                    Text(String(format: "%.1f", viewModel.ride.driverRating))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(viewModel.ride.seatsAvailable)")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.textPrimary)
                Text("seats")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.placeholderMuted)
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    // MARK: - Route Card

    private var routeCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "location.fill", color: .primaryBrand, label: "From", value: viewModel.ride.origin)
            Divider().padding(.leading, 44)
            infoRow(icon: "flag.fill", color: .green, label: "To", value: viewModel.ride.destination)
            Divider().padding(.leading, 44)
            infoRow(icon: "mappin", color: .orange, label: "Zone", value: viewModel.ride.zone)
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func infoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.placeholderMuted)
                Text(value)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Complete Button (driver only)

    private var completeButton: some View {
        Button {
            viewModel.completeRide {
                navigateToComplete = true
            }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Ride")
                            .font(.custom("Poppins-SemiBold", size: 16))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.green)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }
}
