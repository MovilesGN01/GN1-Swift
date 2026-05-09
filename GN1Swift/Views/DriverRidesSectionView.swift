import SwiftUI

/// Inline section shown in Driver Mode listing rides the driver has created.
/// Active rides are sorted soonest-first and shown expanded.
/// Completed/cancelled rides are collapsed under a toggle row.
struct DriverRidesSectionView: View {
    let rides: [Ride]
    let isLoading: Bool
    var onTap: (Ride) -> Void
    var onStartRide: (Ride) -> Void

    @State private var showCompleted = false

    // MARK: - Derived lists

    private var activeRides: [Ride] {
        rides
            .filter { !isFinished($0.status) }
            .sorted { $0.departureTime < $1.departureTime }
    }

    private var completedRides: [Ride] {
        rides
            .filter { isFinished($0.status) }
            .sorted { $0.departureTime > $1.departureTime }   // most recent first
    }

    private func isFinished(_ status: String) -> Bool {
        status == "completed" || status == "cancelled"
    }

    // MARK: - Body

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
                    // Active rides
                    ForEach(activeRides) { ride in
                        rideCard(ride)
                    }

                    if activeRides.isEmpty && completedRides.isEmpty {
                        emptyState
                    }

                    // Completed toggle
                    if !completedRides.isEmpty {
                        completedToggleRow
                        if showCompleted {
                            ForEach(completedRides) { ride in
                                completedRideRow(ride)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.2), value: showCompleted)
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

    // MARK: - Completed Toggle Row

    private var completedToggleRow: some View {
        Button {
            showCompleted.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.placeholderMuted)
                Text("\(completedRides.count) completed ride\(completedRides.count == 1 ? "" : "s")")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.placeholderMuted)
                Spacer()
                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.placeholderMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Active Ride Card (full detail)

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
                    Text(String(format: "$%.0f", ride.price))
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.primaryBrand)
                    Text("\(ride.seatsAvailable) seats")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.placeholderMuted)
                }
            }

            HStack(spacing: 8) {
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

    // MARK: - Completed Ride Row (compact)

    private func completedRideRow(_ ride: Ride) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.gray)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(ride.origin) → \(ride.destination)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)
                Text(ride.departureTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            Text(String(format: "$%.0f", ride.price))
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.placeholderMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func canStart(_ status: String) -> Bool {
        status != "in_progress" && status != "completed" && status != "cancelled" && status != "pending"
    }

    private func statusBadge(_ status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "in_progress": return ("In Progress", Color.primaryBrand)
            case "full":        return ("Full", .orange)
            case "pending":     return ("Pending sync", .orange)
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
