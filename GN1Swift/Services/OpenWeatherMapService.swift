import Foundation

struct WeatherSnapshot {
    let temperatureText: String
    let conditionText: String
    let conditionSymbol: String
}

struct CommuteForecast {
    let message: String
}

struct OpenWeatherResult {
    let current: WeatherSnapshot
    let commute: CommuteForecast
}

enum OpenWeatherError: Error {
    case missingApiKey
    case invalidURL
    case invalidResponse
    case forecastNotFound
}

final class OpenWeatherMapService {
    // Chapinero, Bogota
    private let latitude = 4.6486
    private let longitude = -74.0652

    func fetchHomeWeather() async throws -> OpenWeatherResult {
        let apiKey = apiKeyFromPlist()
        guard !apiKey.isEmpty else {
            throw OpenWeatherError.missingApiKey
        }

        let endpoint = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=en"
        guard let url = URL(string: endpoint) else {
            throw OpenWeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            throw OpenWeatherError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)

        guard let currentEntry = decoded.list.first,
              let currentWeather = currentEntry.weather.first else {
            throw OpenWeatherError.forecastNotFound
        }

        guard let commuteEntry = pickTomorrowCommuteEntry(from: decoded.list),
              let commuteWeather = commuteEntry.weather.first else {
            throw OpenWeatherError.forecastNotFound
        }

        let current = WeatherSnapshot(
            temperatureText: "\(Int(round(currentEntry.main.temp)))°C",
            conditionText: currentWeather.main.capitalized,
            conditionSymbol: symbol(for: currentWeather.main)
        )

        let commute = CommuteForecast(
            message: "Tomorrow 7:00-7:45 AM: \(commuteWeather.description.capitalized) expected, around \(Int(round(commuteEntry.main.temp)))°C."
        )

        return OpenWeatherResult(current: current, commute: commute)
    }

    private func pickTomorrowCommuteEntry(from items: [ForecastEntry]) -> ForecastEntry? {
        let calendar = Calendar.current
        let now = Date()

                  guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                      let targetDate = calendar.date(bySettingHour: 7, minute: 22, second: 0, of: tomorrow) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let datedEntries: [(entry: ForecastEntry, date: Date)] = items.compactMap { entry in
            guard let date = formatter.date(from: entry.dateText) else { return nil }
            return (entry, date)
        }

        return datedEntries.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince(targetDate)) < abs(rhs.date.timeIntervalSince(targetDate))
        })?.entry
    }

    private func symbol(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze", "smoke":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }

    private func apiKeyFromPlist() -> String {
        ((Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ForecastResponse: Decodable {
    let list: [ForecastEntry]
}

private struct ForecastEntry: Decodable {
    let main: ForecastMain
    let weather: [ForecastWeather]
    let dateText: String

    enum CodingKeys: String, CodingKey {
        case main
        case weather
        case dateText = "dt_txt"
    }
}

private struct ForecastMain: Decodable {
    let temp: Double
}

private struct ForecastWeather: Decodable {
    let main: String
    let description: String
}
