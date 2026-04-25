import SwiftUI

struct HomeView: View {
    @State private var weatherSnapshot = WeatherSnapshot(
        temperatureText: "--°C",
        conditionText: "Loading",
        conditionSymbol: "cloud.sun.fill"
    )
    @State private var weatherCondition = ""

    @State private var commuteForecastText = "Tomorrow 7:00-7:45 AM: Loading forecast..."
    @State private var didLoadWeather = false
    @State private var userName = "User"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    HeaderView(
                        weather: weatherSnapshot,
                        userName: userName
                    )

                    WeatherContextBanner(condition: weatherCondition)

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
            
            loadUser()
            loadWeatherFromCloud()
        }
    }

    // Cargar nombre del usuario desde la sesión
    private func loadUser() {
        userName = UserSession.shared.name ?? "User"
    }

    // Cargar clima desde Cloud Function + Firestore
    private func loadWeatherFromCloud() {
        
        // 1. Ejecutar Cloud Function para actualizar Firestore
        CloudFunctionsService.shared.updateWeather()
        
        // 2. Esperar un momento y leer analytics_cache/weatherDemand
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            FirestoreService.shared.loadWeather { data in
                DispatchQueue.main.async {
                    if let w = data {
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
                            commuteForecastText = "Due to rain, expect higher demand during your commute window."
                        case "Cloudy":
                            commuteForecastText = "Cloudy conditions. Rides should be available during your window."
                        default:
                            commuteForecastText = "Clear skies. Normal ride availability expected."
                        }
                    } else {
                        commuteForecastText = "Weather data unavailable."
                    }
                }
            }
        }
    }
}
