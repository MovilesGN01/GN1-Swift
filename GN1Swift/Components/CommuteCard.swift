//
//  CommuteCard.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct CommuteCard: View {
    
    var body: some View {
        VStack(spacing: 16) {
            
            LocationRow(
                icon: "mappin.and.ellipse",
                label: "FROM",
                value: "Chapinero"
            )
            
            LocationRow(
                icon: "flag",
                label: "TO",
                value: "Campus"
            )
            
            HStack {
                Image(systemName: "clock")
                
                Text("Departure Window")
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("7:00 – 7:45 AM")
                    .font(.custom("Poppins-SemiBold", size: 16))
            }
            
            Button {
                
            } label: {
                Text("Start Search")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryBrand)
                    .cornerRadius(12)
            }
            
            Text("Use recurring schedule")
                .foregroundColor(.primaryBrand)
                .font(.custom("Poppins-Medium", size: 14))
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderLine, lineWidth: 1)
        )
    }
}
