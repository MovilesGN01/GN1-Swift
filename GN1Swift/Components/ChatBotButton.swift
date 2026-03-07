//
//  ChatBotButton.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct ChatBotButton: View {
    
    var body: some View {
        
        Button {
            print("Chatbot tapped")
        } label: {
            
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.primaryBrand)
                .clipShape(Circle())
                .shadow(radius: 6)
        }
    }
}
