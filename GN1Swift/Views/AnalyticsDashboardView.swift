import SwiftUI

struct AnalyticsDashboardView: View {

    @StateObject private var vm = AnalyticsDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.backgroundApp.ignoresSafeArea()

                VStack(spacing: 0) {
                    if vm.isOffline { offlineBanner }

                    if vm.isLoading {
                        Spacer()
                        ProgressView("Loading analytics…")
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                cacheStatusChip

                                if let zones = vm.zoneAnalytics {
                                    zonesSection(zones)
                                }

                                if let peak = vm.peakHoursAnalytics {
                                    peakHoursSection(peak)
                                }

                                if vm.zoneAnalytics == nil && vm.peakHoursAnalytics == nil {
                                    emptyState
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Demand Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { vm.forceRefresh() } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryBrand)
                    }
                }
            }
            .onAppear { vm.load() }
        }
    }

    // MARK: - Cache status chip

    private var cacheStatusChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(vm.cacheHit ? Color.green : Color.primaryBrand)
                .frame(width: 8, height: 8)
            Text(vm.cacheHit ? "Served from cache" : "Live data")
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(.textSecondary)
            if let ts = vm.lastRefreshed {
                Text("· \(timeAgo(ts))")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.surfaceCard)
        .cornerRadius(20)
    }

    // MARK: - Top Zones

    private func zonesSection(_ data: CachedZoneAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Top Demand Zones")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.textPrimary)
                Spacer()
                Label(data.mostDemandedZone, systemImage: "mappin.circle.fill")
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.primaryBrand)
            }

            let sorted = data.zones.sorted { $0.value > $1.value }
            let maxCount = sorted.first?.value ?? 1

            ForEach(sorted.prefix(6), id: \.key) { zone, count in
                zoneBar(name: zone, count: count, max: maxCount,
                        isTop: zone == data.mostDemandedZone)
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
    }

    private func zoneBar(name: String, count: Int, max: Int, isTop: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.textPrimary)
                if isTop {
                    Text("TOP")
                        .font(.custom("Poppins-Bold", size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.primaryBrand)
                        .cornerRadius(4)
                }
                Spacer()
                Text("\(count) rides")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderLine)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isTop ? Color.primaryBrand : Color.primaryBrand.opacity(0.4))
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Peak Hours

    private func peakHoursSection(_ data: CachedPeakHoursAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Peak Hours")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                peakPill(label: "Morning Peak",
                         hour: data.morningPeak,
                         icon: "sunrise.fill",
                         color: .orange)
                peakPill(label: "Evening Peak",
                         hour: data.eveningPeak,
                         icon: "sunset.fill",
                         color: .purple)
            }

            let maxCount = data.hours.values.max() ?? 1
            VStack(alignment: .leading, spacing: 6) {
                Text("Hourly distribution (5 AM – 10 PM)")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(5..<23, id: \.self) { hour in
                        let count = data.hours[hour] ?? 0
                        let isMorning = hour == data.morningPeak
                        let isEvening = hour == data.eveningPeak
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isMorning ? Color.orange :
                                      isEvening ? Color.purple :
                                      Color.primaryBrand.opacity(0.35))
                                .frame(width: 14,
                                       height: max(4, 60 * CGFloat(count) / CGFloat(maxCount)))
                            Text("\(hour)")
                                .font(.system(size: 8))
                                .foregroundColor(.placeholderMuted)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLine, lineWidth: 1))
    }

    private func peakPill(label: String, hour: Int?, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(hour.map { String(format: "%02d:00", $0) } ?? "--:--")
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(hour != nil ? .textPrimary : .placeholderMuted)
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Offline banner

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .semibold))
            Text("Offline — showing last cached data")
                .font(.custom("Poppins-Regular", size: 12))
            Spacer()
        }
        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 1, green: 0.95, blue: 0.8))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.placeholderMuted)
            Text("No analytics data yet")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.textPrimary)
            Text("Data is collected as rides are completed.")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        guard seconds >= 60 else { return "just now" }
        return "\(seconds / 60) min ago"
    }
}
