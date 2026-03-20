import SwiftUI

struct HomeView: View {
    @State private var weatherSnapshot = WeatherSnapshot(
        temperatureText: "--°C",
        conditionText: "Loading",
        conditionSymbol: "cloud.sun.fill"
    )
    @State private var commuteForecastText = "Tomorrow 7:00-7:45 AM: Loading forecast..."
    @State private var didLoadWeather = false

    private let weatherService = OpenWeatherMapService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    HeaderView(weather: weatherSnapshot)
                    
                    Text("Plan Your Commute")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)
                    
                    CommuteCard(commuteForecastText: commuteForecastText)
                    
                    Text("Explore Alternatives")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 16) {
                        AlternativeCard(
                            icon: "car.fill",
                            title: "Carpool",
                            subtitle: "Shared rides with peers"
                        )
                        
                        AlternativeCard(
                            icon: "bus.fill",
                            title: "University Bus",
                            subtitle: "Scheduled campus routes"
                        )
                    }
                    
                    HStack {
                        Text("Recurring Rides")
                            .font(.custom("Poppins-Bold", size: 22))
                        
                        Spacer()
                        
                        Text("View All")
                            .foregroundColor(.primaryBrand)
                            .font(.custom("Poppins-Medium", size: 14))
                    }
                    
                    RecurringRideCard(
                        icon: "house",
                        title: "Home to Engineering Lab",
                        subtitle: "Mon, Wed, Fri • 08:30 AM"
                    )
                    
                    RecurringRideCard(
                        icon: "graduationcap",
                        title: "Campus to Chapinero",
                        subtitle: "Daily • 05:45 PM"
                    )
                    
                }
                .padding()
            }
            .background(Color.backgroundApp)
        }
        .task {
            guard !didLoadWeather else { return }
            didLoadWeather = true
            await loadWeather()
        }
    }

    @MainActor
    private func loadWeather() async {
        do {
            let weather = try await weatherService.fetchHomeWeather()
            weatherSnapshot = weather.current
            commuteForecastText = weather.commute.message
        } catch OpenWeatherError.missingApiKey {
            weatherSnapshot = WeatherSnapshot(
                temperatureText: "--°C",
                conditionText: "Config required",
                conditionSymbol: "exclamationmark.triangle.fill"
            )
            commuteForecastText = "Add OPENWEATHER_API_KEY in Info.plist to load tomorrow forecast."
        } catch {
            weatherSnapshot = WeatherSnapshot(
                temperatureText: "--°C",
                conditionText: "Unavailable",
                conditionSymbol: "cloud.slash.fill"
            )
            commuteForecastText = "Could not load weather for tomorrow 7:00-7:45 AM."
        }
    }
}
