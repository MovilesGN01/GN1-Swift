import SwiftUI

struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                appBar
                content
            }
            .background(Color.backgroundApp)
            .onAppear { viewModel.loadRecommendations() }
        }
    }

    // MARK: - App Bar

    private var appBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Recommended Rides")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)
                Text("Personalized for you")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View { 
        if viewModel.isLoading {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Finding the best rides for you…")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        } else if viewModel.recommendedRides.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Based on your ride history and favorite zones")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ForEach(viewModel.recommendedRides) { ride in
                        NavigationLink(destination: RideDetailView(ride: ride)) {
                            recommendationCard(ride)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundColor(.borderLine)
            Text("No recommendations yet")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.textPrimary)
            Text("Take more rides so we can learn your preferences and suggest the best commute options.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Recommendation Card

    private func recommendationCard(_ ride: Ride) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(.primaryBrand)
                        Text("Recommended")
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundColor(.primaryBrand)
                    }
                    Text("\(ride.origin) → \(ride.destination)")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Driver: \(ride.driverName)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 11))
                        Text(String(format: "%.1f", ride.driverRating))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(ride.seatsAvailable) seats")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                    Text(ride.zone)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.placeholderMuted)
                }
            }
        }
        .padding(16)
        .background(Color.primaryBrand.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primaryBrand.opacity(0.18), lineWidth: 1))
        .cornerRadius(16)
    }
}
