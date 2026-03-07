//
//  ServiceCard.swift
//  GN1-Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct ServiceCard: View {
    var body: some View {
        HStack(spacing: 15) {
            // Placeholder de imagen
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.borderLine)
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "hammer.fill").foregroundColor(.textSecondary))
            
            VStack(alignment: .leading, spacing: 4) {
                // Badge de CAS (Context-Aware)
                Text("CERCA DE TI")
                    .font(.custom("Poppins-Bold", size: 10))
                    .foregroundColor(.primaryBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.primaryBrand.opacity(0.1))
                    .cornerRadius(4)
                
                Text("Reparación de Hogar")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.textPrimary)
                
                Text("Disponible ahora • 0.5 km")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
