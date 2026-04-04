import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            Divider()
            messageList
            inputBar
        }
        .background(Color.backgroundApp)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.primaryBrand.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryBrand)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("UniRide Assistant")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.textPrimary)
                Text("AI-powered commute helper")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 48) }

            Text(message.content)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(message.isFromUser ? .white : .textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isFromUser ? Color.primaryBrand : Color.surfaceCard)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(message.isFromUser ? Color.clear : Color.borderLine, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser { Spacer(minLength: 48) }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.placeholderMuted)
                        .frame(width: 7, height: 7)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surfaceCard)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.borderLine, lineWidth: 1))

            Spacer(minLength: 48)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your commute…", text: $inputText, axis: .vertical)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textPrimary)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                .cornerRadius(12)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.primaryBrand.opacity(0.4) : Color.primaryBrand)
                    .cornerRadius(12)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundApp)
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Action

    private func sendMessage() {
        let text = inputText
        inputText = ""
        viewModel.send(text)
    }
}
