//
//  ChatView.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct ChatView: View {

    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""

    var body: some View {
        VStack {

            // Header
            HStack {
                Text("UniRide Assistant")
                    .font(.custom("Poppins-SemiBold", size: 18))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .padding()

            Divider()

            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    Text("Hi! 👋 I'm UniRide assistant.\nTell me your plan and I'll suggest the best commute.")
                        .padding()
                        .background(Color.surfaceCard)
                        .cornerRadius(12)

                }
                .padding()
            }

            Spacer()

            // Input
            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    print(messageText)
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
    }
}
