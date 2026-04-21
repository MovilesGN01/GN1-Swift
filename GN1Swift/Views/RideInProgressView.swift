import SwiftUI
import MapKit

struct RideInProgressView: View {
    @StateObject private var viewModel: RideInProgressViewModel
    private let facade: AppFacadeType
    @Environment(\.dismiss) private var dismiss
    var onFinished: () -> Void

    init(ride: Ride, onFinished: @escaping () -> Void, facade: AppFacadeType = AppFacade.shared) {
        self.facade = facade
        _viewModel = StateObject(wrappedValue: RideInProgressViewModel(ride: ride, facade: facade))
        self.onFinished = onFinished
    }

    var body: some View {
        VStack(spacing: 0) {
            appBar

            Map {
                UserAnnotation()
                if let coord = viewModel.originCoordinate {
                    Marker("Origin", coordinate: coord)
                        .tint(.blue)
                }
                if let coord = viewModel.destinationCoordinate {
                    Marker("Destination", coordinate: coord)
                        .tint(.green)
                }
                if let route = viewModel.route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .frame(height: 260)

            ScrollView {
                VStack(spacing: 16) {
                    statusBanner
                    routeCard
                    passengersCard
                }
                .padding(16)
            }

            finishButton
                .padding(16)
        }
        .background(Color.backgroundApp)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startListening()
            facade.requestLocationPermissionAndStart()
        }
        .onDisappear { viewModel.stopListeningNow() }
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
                Text("Ride In Progress")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)
                Text("Press Finish Ride when you arrive")
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
            Circle()
                .fill(Color.primaryBrand)
                .frame(width: 10, height: 10)
            Text("In Progress")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(.primaryBrand)
            Spacer()
            Text(viewModel.ride.departureTime.formatted(date: .omitted, time: .shortened))
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.primaryBrand.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryBrand.opacity(0.25), lineWidth: 1))
        .cornerRadius(12)
    }

    // MARK: - Route Card

    private var routeCard: some View {
        VStack(spacing: 0) {
            routeRow(icon: "location.fill", color: .primaryBrand, label: "Origin",
                     value: viewModel.ride.origin)
            Divider().padding(.leading, 44)
            routeRow(icon: "flag.fill", color: .green, label: "Destination",
                     value: viewModel.ride.destination)
            Divider().padding(.leading, 44)
            routeRow(icon: "mappin", color: .orange, label: "Zone",
                     value: viewModel.ride.zone)
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func routeRow(icon: String, color: Color, label: String, value: String) -> some View {
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

    // MARK: - Passengers Card

    private var passengersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACCEPTED PASSENGERS")
                    .font(.custom("Poppins-SemiBold", size: 11))
                    .tracking(0.8)
                    .foregroundColor(.placeholderMuted)
                Spacer()
                Text("\(viewModel.acceptedPassengers.count)")
                    .font(.custom("Poppins-Bold", size: 13))
                    .foregroundColor(.primaryBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryBrand.opacity(0.1))
                    .cornerRadius(6)
            }

            if viewModel.acceptedPassengers.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.3")
                        .foregroundColor(.placeholderMuted)
                    Text("No accepted passengers yet")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.placeholderMuted)
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.acceptedPassengers) { passenger in
                        passengerRow(passenger)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func passengerRow(_ request: RideRequest) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.primaryBrand.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(request.passengerName.prefix(1)))
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.primaryBrand)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(request.passengerName)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
                Text("Accepted · \(request.requestTime.formatted(date: .omitted, time: .shortened))")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Finish Button

    private var finishButton: some View {
        Button {
            viewModel.finishRide {
                onFinished()
            }
        } label: {
            ZStack {
                if viewModel.isFinishing {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish Ride")
                            .font(.custom("Poppins-SemiBold", size: 16))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.green)
            .cornerRadius(14)
        }
        .disabled(viewModel.isFinishing)
    }
}
