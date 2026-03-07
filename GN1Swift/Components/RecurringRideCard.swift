//
//  RecurringRideCard.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct RecurringRideCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            
            Image(systemName: icon)
                .frame(width: 40, height: 40)
                .background(Color.surfaceCard)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                
                Text(subtitle)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderLine)
        )
    }
}
