import SwiftUI

struct RideDetailView: View {
    let ride: Ride
    @StateObject private var viewModel: RideDetailViewModel

    init(ride: Ride, facade: AppFacadeType = AppFacade.shared) {
        self.ride = ride
        _viewModel = StateObject(wrappedValue: RideDetailViewModel(ride: ride, facade: facade))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    driverCard
                    tripSummarySection
                    aboutSection
                    safetySection
                }
                .padding()
            }

            actionButtons
        }
        .background(Color.backgroundApp)
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkExistingRequest()
            viewModel.loadDriverGamification()
        }
        .alert("Ride Reserved!", isPresented: $viewModel.requestSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your request has been sent to the driver.")
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

    // MARK: - Driver Card

    private var driverCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(ride.driverName.prefix(1)))
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.primaryBrand)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(ride.driverName)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 13))
                        Text(String(format: "%.1f", ride.driverRating))
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Text(ride.zone)
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .foregroundColor(.primaryBrand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primaryBrand.opacity(0.1))
                    .cornerRadius(8)
            }

            Divider()

            if let gamification = viewModel.driverGamification {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.primaryBrand)
                            Text("\(gamification.level)")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.textPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Points")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.orange)
                            Text("\(gamification.points)")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.textPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Badges")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: "award.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(gamification.unlockedBadgesCount)")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                .padding(12)
                .background(Color.primaryBrand.opacity(0.05))
                .cornerRadius(12)
            } else if viewModel.isLoadingGamification {
                HStack {
                    ProgressView()
                        .tint(.primaryBrand)
                    Text("Loading gamification profile...")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(12)
            }
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(20)
    }

    // MARK: - Trip Summary

    private var tripSummarySection: some View {
        section(title: "Trip summary") {
            detail(icon: "location", label: "From", value: ride.origin)
            Divider()
            detail(icon: "flag", label: "To", value: ride.destination)
            Divider()
            detail(icon: "clock", label: "Departure",
                   value: ride.departureTime.formatted(date: .abbreviated, time: .shortened))
            Divider()
            detail(icon: "person.3", label: "Seats available", value: "\(ride.seatsAvailable)")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        section(title: "About this ride") {
            Text("This is a regular commute within the Uniandes community. The driver follows a consistent schedule and prioritizes punctuality and comfort for all passengers.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Safety

    private var safetySection: some View {
        section(title: "Safety signals") {
            VStack(alignment: .leading, spacing: 12) {
                safetyRow("Verified university profile")
                Divider()
                safetyRow("High rating driver")
                Divider()
                safetyRow("Trusted community ride")
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                // Chat placeholder
            } label: {
                Text("Chat")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.primaryBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryBrand, lineWidth: 1.5))
            }

            Button { viewModel.requestRide() } label: {
                ZStack {
                    if viewModel.isRequesting {
                        ProgressView().tint(.white)
                    } else {
                        Text(viewModel.alreadyRequested ? "Request already sent" : "Reserve")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.alreadyRequested ? Color.placeholderMuted
                    : viewModel.requestSuccess  ? Color.green
                    : Color.primaryBrand
                )
                .cornerRadius(12)
            }
            .disabled(viewModel.isRequesting || viewModel.requestSuccess || viewModel.alreadyRequested)
        }
        .padding()
    }

    // MARK: - Reusable Components

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.textPrimary)
            content()
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }

    func detail(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.primaryBrand)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(value)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
        }
    }

    func safetyRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.textPrimary)
            Spacer()
        }
    }
}
