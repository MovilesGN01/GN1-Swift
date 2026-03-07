//
//  WeatherBadge.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct WeatherBadge: View {
    
    var body: some View {
        HStack(spacing: 8) {
            
            Image(systemName: "sun.max.fill")
            
            VStack(alignment: .leading) {
                Text("18°C")
                    .font(.custom("Poppins-SemiBold", size: 14))
                
                Text("Sunny")
                    .font(.custom("Poppins-Regular", size: 12))
            }
        }
        .padding(10)
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }
}
