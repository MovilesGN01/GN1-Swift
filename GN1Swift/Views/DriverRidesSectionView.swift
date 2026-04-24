import SwiftUI

/// Inline section shown in Driver Mode listing rides the driver has created.
/// Tapping "View Requests" navigates to DriverRequestsView.
/// Tapping "Start Ride" calls the startRide CF and navigates to RideInProgressView.
struct DriverRidesSectionView: View {
    let rides: [Ride]
    let isLoading: Bool
    var onTap: (Ride) -> Void         // View Requests
    var onStartRide: (Ride) -> Void   // Start Ride

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if rides.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(rides) { ride in
                        rideCard(ride)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Text("MY CREATED RIDES")
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
            Image(systemName: "car")
                .foregroundColor(.placeholderMuted)
            Text("You haven't created any rides yet")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.placeholderMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Ride Card

    private func rideCard(_ ride: Ride) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ride.origin) → \(ride.destination)")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("Zone: \(ride.zone)")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.placeholderMuted)
                        Text(ride.departureTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.placeholderMuted)
                    }
                    Text(ride.urgencyLabel)
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ride.urgencyColor)
                        .cornerRadius(8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    statusBadge(ride.status)
                    Text("\(ride.seatsAvailable) seats")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.placeholderMuted)
                }
            }

            // Action row
            HStack(spacing: 8) {
                // "View Requests" is only meaningful once the ride is live in Firebase.
                if ride.status != "pending" {
                    Button { onTap(ride) } label: {
                        HStack(spacing: 4) {
                            Text("View Requests")
                                .font(.custom("Poppins-SemiBold", size: 12))
                                .foregroundColor(.primaryBrand)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primaryBrand)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("Will sync when online")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                }

                Spacer()

                // "Start Ride" only while the ride hasn't been started or completed
                if canStart(ride.status) {
                    Button { onStartRide(ride) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                            Text("Start Ride")
                                .font(.custom("Poppins-SemiBold", size: 12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    /// "Start Ride" is available only for Firebase rides that are open or full.
    private func canStart(_ status: String) -> Bool {
        status != "in_progress" && status != "completed" && status != "pending"
    }

    private func statusBadge(_ status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "in_progress": return ("In Progress", Color.primaryBrand)
            case "completed":   return ("Completed", .gray)
            case "full":        return ("Full", .orange)
            case "pending":     return ("Pending", Color.orange)
            default:            return ("Active", .green)
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
