import SwiftUI

struct WeatherContextBanner: View {
    let condition: String

    private var config: (message: String, icon: String, foreground: Color, background: Color) {
        switch condition {
        case "Rain":
            return (
                "Rain detected. Ride availability may be reduced. Consider booking early.",
                "exclamationmark.triangle.fill",
                Color(red: 0.75, green: 0.25, blue: 0.05),
                Color(red: 1.0, green: 0.93, blue: 0.87)
            )
        case "Cloudy":
            return (
                "Cloudy weather. Demand may slightly increase.",
                "cloud.fill",
                Color(red: 0.35, green: 0.40, blue: 0.50),
                Color(red: 0.93, green: 0.94, blue: 0.96)
            )
        default: // "Clear"
            return (
                "Good weather for commuting. Ride availability should be normal.",
                "checkmark.circle.fill",
                Color(red: 0.13, green: 0.55, blue: 0.25),
                Color(red: 0.88, green: 0.97, blue: 0.90)
            )
        }
    }

    var body: some View {
        if !condition.isEmpty && condition != "Loading" {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: config.icon)
                    .foregroundColor(config.foreground)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(config.message)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(config.foreground)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Weather conditions can affect transportation demand")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(config.foreground.opacity(0.65))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(config.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(config.foreground.opacity(0.25), lineWidth: 1)
            )
        }
    }
}
