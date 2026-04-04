import SwiftUI

/// Inline section shown in Passenger Mode listing the user's own ride requests and their status.
struct MyRequestsSectionView: View {
    @ObservedObject var viewModel: MyRequestsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if viewModel.isLoading {
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
        Text("MY RIDE REQUESTS")
            .font(.custom("Poppins-SemiBold", size: 11))
            .tracking(0.8)
            .foregroundColor(.placeholderMuted)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.placeholderMuted)
            Text("You haven't requested any rides yet")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.placeholderMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Request Card

    private func requestCard(_ request: RideRequest) -> some View {
        HStack(spacing: 14) {
            // Status icon
            Circle()
                .fill(statusColor(request.status).opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: statusIcon(request.status))
                        .font(.system(size: 16))
                        .foregroundColor(statusColor(request.status))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Ride request")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
                Text("Sent \(request.requestTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            statusBadge(request.status)
        }
        .padding(14)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor(request.status).opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private func statusBadge(_ status: String) -> some View {
        let (label, color) = statusInfo(status)
        return Text(label)
            .font(.custom("Poppins-SemiBold", size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }

    private func statusInfo(_ status: String) -> (String, Color) {
        switch status {
        case "accepted": return ("Accepted", .green)
        case "rejected": return ("Rejected", .red)
        default: return ("Pending", .orange)
        }
    }

    private func statusColor(_ status: String) -> Color { statusInfo(status).1 }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        default: return "clock.fill"
        }
    }
}
