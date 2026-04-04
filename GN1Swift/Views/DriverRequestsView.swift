import SwiftUI

struct DriverRequestsView: View {
    @StateObject private var viewModel: DriverRequestsViewModel
    @Environment(\.dismiss) private var dismiss

    init(rideId: String? = nil) {
        _viewModel = StateObject(wrappedValue: DriverRequestsViewModel(rideId: rideId))
    }

    var body: some View {
        VStack(spacing: 0) {
            appBar

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading requests...")
                Spacer()
            } else if viewModel.requests.isEmpty {
                emptyState
            } else {
                requestList
            }
        }
        .background(Color.backgroundApp)
        .navigationBarHidden(true)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListeningNow() }
    }

    // MARK: - App Bar

    private var appBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ride Requests")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)
                Text("Accept or reject passengers")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            if !viewModel.requests.isEmpty {
                Text("\(viewModel.requests.filter { $0.status == "pending" }.count)")
                    .font(.custom("Poppins-Bold", size: 12))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.primaryBrand)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundColor(.borderLine)
            Text("No requests yet")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.textPrimary)
            Text("Passenger requests will appear here in real time.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Request List

    private var requestList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.requests) { request in
                    requestCard(request)
                }
            }
            .padding(16)
        }
    }

    private func requestCard(_ request: RideRequest) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.12))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(String(request.passengerName.prefix(1)))
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.primaryBrand)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.passengerName)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Requested at \(request.requestTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                }

                Spacer()
                statusBadge(for: request.status)
            }

            if request.status == "pending" {
                HStack(spacing: 12) {
                    Button { viewModel.reject(request) } label: {
                        Text("Reject")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }

                    Button { viewModel.accept(request) } label: {
                        Text("Accept")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primaryBrand)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func statusBadge(for status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "accepted": return ("Accepted", .green)
            case "rejected": return ("Rejected", .red)
            default: return ("Pending", .orange)
            }
        }()
        return Text(label)
            .font(.custom("Poppins-SemiBold", size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }
}
