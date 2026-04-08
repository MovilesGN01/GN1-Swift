//
//  View+InputStyle.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 3/04/26.
//

import SwiftUI

extension View {
    func inputStyle() -> some View {
        self
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderLine, lineWidth: 1)
            )
            .cornerRadius(12)
    }
}
