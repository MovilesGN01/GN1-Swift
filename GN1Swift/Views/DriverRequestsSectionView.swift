import SwiftUI

/// Inline section shown in Driver Mode listing incoming passenger requests.
/// Provides Accept / Reject buttons directly in the card.
struct DriverRequestsSectionView: View {
    @ObservedObject var viewModel: DriverRidesViewModel

    private var pendingCount: Int {
        viewModel.requests.filter { $0.status == "pending" }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if viewModel.isLoadingRequests {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if viewModel.requests.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.requests) { request in
                        requestCard(request)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Text("PASSENGER REQUESTS")
                .font(.custom("Poppins-SemiBold", size: 11))
                .tracking(0.8)
                .foregroundColor(.placeholderMuted)

            Spacer()

            if pendingCount > 0 {
                Text("\(pendingCount) pending")
                    .font(.custom("Poppins-SemiBold", size: 11))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3")
                .foregroundColor(.placeholderMuted)
            Text("No passenger requests yet")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.placeholderMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Request Card

    private func requestCard(_ request: RideRequest) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(request.passengerName.prefix(1)))
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.primaryBrand)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.passengerName)
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.textPrimary)
                    Text("Requested \(request.requestTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                }

                Spacer()
                statusBadge(request.status)
            }

            if request.status == "pending" {
                HStack(spacing: 10) {
                    Button { viewModel.reject(request) } label: {
                        Text("Reject")
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }

                    Button {
                        viewModel.accept(request)
                    } label: {
                        Text("Accept")
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.primaryBrand)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func statusBadge(_ status: String) -> some View {
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
