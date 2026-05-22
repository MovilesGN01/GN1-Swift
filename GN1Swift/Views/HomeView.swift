import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int

    @StateObject private var vm = HomeViewModel()

    @State private var weatherSnapshot = WeatherSnapshot(
        temperatureText: "--°C",
        conditionText: "Loading",
        conditionSymbol: "cloud.sun.fill"
    )
    @State private var weatherCondition = ""
    @State private var commuteForecastText = ""
    @State private var didLoadWeather = false
    @State private var showAnalytics = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sticky offline banner — outside ScrollView so it never scrolls away
                if vm.isOffline {
                    homeOfflineBanner
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    HeaderView(
                        weather: weatherSnapshot,
                        userName: UserSession.shared.name ?? "User"
                    )

                    WeatherContextBanner(condition: weatherCondition)

                    // ── Next Ride ──────────────────────────────────────────────
                    Text("Your Next Ride")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)

                    nextRideSection

                    // ── Stats ──────────────────────────────────────────────────
                    Text("Your Stats")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)

                    statsStrip

                    // ── Demand Analytics ───────────────────────────────────────
                    demandAnalyticsCard

                    // ── Recent Rides ───────────────────────────────────────────
                    HStack {
                        Text("Recent Rides")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button {
                            selectedTab = 1
                        } label: {
                            Text("View All")
                                .foregroundColor(.primaryBrand)
                                .font(.custom("Poppins-Medium", size: 14))
                        }
                    }

                    recentHistorySection
                }
                .padding()
            }
            .background(Color.backgroundApp)
            } // VStack
        }
        .sheet(isPresented: $showAnalytics) { AnalyticsDashboardView() }
        .animation(.easeInOut(duration: 0.25), value: vm.isOffline)
        .task {
            vm.load()
            guard !didLoadWeather else { return }
            didLoadWeather = true
            loadWeatherFromCloud()
        }
    }

    // MARK: - Offline Banner

    private var homeOfflineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("You're offline")
                    .font(.custom("Poppins-SemiBold", size: 13))
                Text("Showing locally saved data")
                    .font(.custom("Poppins-Regular", size: 11))
            }
            Spacer()
        }
        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 1, green: 0.95, blue: 0.8))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3)),
            alignment: .bottom
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Next Ride Section

    @ViewBuilder
    private var nextRideSection: some View {
        if vm.isLoading && vm.nextRide == nil {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceCard)
                .frame(height: 120)
                .overlay(ProgressView())
        } else if let ride = vm.nextRide {
            nextRideCard(ride)
        } else {
            noNextRideCard
        }
    }

    private func nextRideCard(_ ride: CachedNextRide) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ride.origin) → \(ride.destination)")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.textPrimary)
                    Text("Driver: \(ride.driverName)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.placeholderMuted)
                        Text(ride.departureTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.placeholderMuted)
                    }
                }
                Spacer()
                statusBadge(for: ride.status)
            }

            Text(ride.status == "accepted"
                 ? "Your seat is confirmed. Be on time!"
                 : "Waiting for driver confirmation…")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(ride.status == "accepted" ? .green : .orange)
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private var noNextRideCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.circle")
                .font(.system(size: 36))
                .foregroundColor(.placeholderMuted)
            Text("No upcoming rides")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(.textPrimary)
            Text("Find available rides and reserve your seat.")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                selectedTab = 1
            } label: {
                Text("Find a Ride")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.primaryBrand)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    private func statusBadge(for status: String) -> some View {
        let isAccepted = status == "accepted"
        return Text(isAccepted ? "Confirmed" : "Pending")
            .font(.custom("Poppins-SemiBold", size: 11))
            .foregroundColor(isAccepted ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((isAccepted ? Color.green : Color.orange).opacity(0.12))
            .cornerRadius(8)
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 12) {
            statChip(
                icon: "star.fill",
                value: vm.stats.map { "\($0.points)" } ?? "--",
                label: "Points",
                color: .yellow
            )
            statChip(
                icon: "flame.fill",
                value: vm.stats.map { "Lv \($0.level)" } ?? "--",
                label: "Level",
                color: .orange
            )
            statChip(
                icon: "car.fill",
                value: vm.stats.map { "\($0.totalRides)" } ?? "--",
                label: "Rides",
                color: .primaryBrand
            )
        }
    }

    private func statChip(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.placeholderMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(12)
    }

    // MARK: - Recent History Section

    @ViewBuilder
    private var recentHistorySection: some View {
        if vm.isLoading && vm.recentHistory.isEmpty {
            ProgressView().frame(maxWidth: .infinity)
        } else if vm.recentHistory.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.placeholderMuted)
                Text("No rides yet — take your first ride!")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.placeholderMuted)
            }
            .padding(.vertical, 8)
        } else {
            VStack(spacing: 8) {
                ForEach(vm.recentHistory) { item in
                    historyRow(item)
                }
            }
        }
    }

    private func historyRow(_ item: CachedHistoryItem) -> some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.primaryBrand.opacity(0.7))
                .frame(width: 40, height: 40)
                .background(Color.primaryBrand.opacity(0.08))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.origin) → \(item.destination)")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
                Text(item.completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.placeholderMuted)
        }
        .padding(14)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(16)
    }

    // MARK: - Demand Analytics Card

    private var demandAnalyticsCard: some View {
        Button { showAnalytics = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.primaryBrand)
                    .frame(width: 44, height: 44)
                    .background(Color.primaryBrand.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Demand Analytics")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Top zones & peak hours")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.placeholderMuted)
            }
            .padding(16)
            .background(Color.surfaceCard)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Weather (unchanged)

    private func loadWeatherFromCloud() {
        CloudFunctionsService.shared.updateWeather()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            FirestoreService.shared.loadWeather { data in
                DispatchQueue.main.async {
                    guard let w = data else {
                        commuteForecastText = "Weather data unavailable."
                        return
                    }
                    let symbol: String
                    switch w.weather {
                    case "Rain":   symbol = "cloud.rain.fill"
                    case "Cloudy": symbol = "cloud.fill"
                    default:       symbol = "sun.max.fill"
                    }
                    weatherCondition = w.weather
                    weatherSnapshot = WeatherSnapshot(
                        temperatureText: "\(Int(w.temperature))°C",
                        conditionText: w.weather,
                        conditionSymbol: symbol
                    )
                    switch w.weather {
                    case "Rain":
                        commuteForecastText = "Rain expected — higher demand during your commute window."
                    case "Cloudy":
                        commuteForecastText = "Cloudy conditions. Rides should be available."
                    default:
                        commuteForecastText = "Clear skies. Normal ride availability expected."
                    }
                }
            }
        }
    }
}
