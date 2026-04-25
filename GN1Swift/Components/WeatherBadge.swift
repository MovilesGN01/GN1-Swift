//
//  WeatherBadge.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct WeatherBadge: View {
    let weather: WeatherSnapshot
    
    var body: some View {
        HStack(spacing: 8) {
            
            Image(systemName: weather.conditionSymbol)
            
            VStack(alignment: .leading) {
                Text(weather.temperatureText)
                    .font(.custom("Poppins-SemiBold", size: 14))
                
                Text(weather.conditionText)
                    .font(.custom("Poppins-Regular", size: 12))
            }
        }
        .padding(10)
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }
}
