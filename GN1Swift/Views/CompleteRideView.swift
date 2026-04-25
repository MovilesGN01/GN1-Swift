import SwiftUI

struct CompleteRideView: View {
    let ride: Ride
    @State private var navigateToRate = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    completionHeader
                    summaryCard
                }
                .padding(16)
            }
            bottomButtons
        }
        .background(Color.backgroundApp)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToRate) {
            RateRideView(rideId: ride.id)
        }
    }

    // MARK: - Header

    private var completionHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.green.opacity(0.12))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                )
                .padding(.top, 32)

            Text("Ride Complete!")
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.textPrimary)

            Text("Thank you for driving. Your contribution helps build\nthe university community.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TRIP SUMMARY")
                .font(.custom("Poppins-SemiBold", size: 11))
                .tracking(0.8)
                .foregroundColor(.placeholderMuted)

            summaryRow(icon: "location.fill", color: .primaryBrand, label: "From", value: ride.origin)
            Divider()
            summaryRow(icon: "flag.fill", color: .green, label: "To", value: ride.destination)
            Divider()
            summaryRow(icon: "mappin", color: .orange, label: "Zone", value: ride.zone)
            Divider()
            summaryRow(icon: "clock", color: .primaryBrand, label: "Departed",
                       value: ride.departureTime.formatted(date: .omitted, time: .shortened))
            Divider()
            summaryRow(icon: "person.2.fill", color: .primaryBrand, label: "Seats offered",
                       value: "\(ride.seatsAvailable)")
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func summaryRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 22)
            Text(label)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button { navigateToRate = true } label: {
                Text("Rate the Ride")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primaryBrand)
                    .cornerRadius(12)
            }
        }
        .padding(16)
    }
}
