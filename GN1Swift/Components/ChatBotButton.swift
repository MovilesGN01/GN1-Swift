//
//  ChatBotButton.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI


struct ChatBotButton: View {

    var action: () -> Void

    var body: some View {

        Button(action: action) {

            Image(systemName: "message.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.primaryBrand)
                .clipShape(Circle())
                .shadow(radius: 6)
        }
    }
}
