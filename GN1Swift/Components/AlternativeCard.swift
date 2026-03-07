//
//  AlternativeCard.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct AlternativeCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.primaryBrand)
            
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 16))
            
            Text(subtitle)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
            
            Button("VIEW OPTION") {
                
            }
            .font(.custom("Poppins-SemiBold", size: 12))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.primaryBrand)
            .foregroundColor(.white)
            .cornerRadius(8)
            
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }
}
