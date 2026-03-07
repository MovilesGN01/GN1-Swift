//
//  LocationRow.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct LocationRow: View {
    
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: icon)
                .foregroundColor(.primaryBrand)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(label)
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderLine, lineWidth: 1)
        )
    }
}
