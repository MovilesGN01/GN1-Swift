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
            bottomBar
        }
        .background(Color.backgroundApp)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isOffline)
        .animation(.easeInOut(duration: 0.2), value: viewModel.offlineOptions.map(\.id))
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.primaryBrand.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: viewModel.isOffline ? "wifi.slash" : "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.isOffline ? .secondary : .primaryBrand)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("UniRide Assistant")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.textPrimary)
                Text(viewModel.isOffline ? "Offline mode" : "AI-powered commute helper")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(viewModel.isOffline ? .secondary : .placeholderMuted)
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
                        typingIndicator.id("typing")
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
                ForEach(0..<3, id: \.self) { _ in
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

    // MARK: - Bottom Bar (online input OR offline options)

    @ViewBuilder
    private var bottomBar: some View {
        if viewModel.isOffline {
            offlineOptionsPanel
        } else {
            inputBar
        }
    }

    // MARK: - Offline Options Panel

    private var offlineOptionsPanel: some View {
        VStack(spacing: 0) {
            Divider()

            // Navigation controls
            HStack(spacing: 8) {
                if viewModel.canGoBack {
                    Button {
                        viewModel.goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button {
                        viewModel.goToRoot()
                    } label: {
                        Text("Main menu")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.primaryBrand)
                    }
                } else {
                    // Root level: offer to retry AI
                    Spacer()
                    Button {
                        viewModel.retryOnline()
                    } label: {
                        Label("Try AI again", systemImage: "arrow.clockwise")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.primaryBrand)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Option chips or "back to menu" when at a leaf
            if viewModel.offlineOptions.isEmpty {
                // Leaf node reached — show helpers
                HStack(spacing: 8) {
                    optionChip(label: "↩ Back", action: { viewModel.goBack() })
                    optionChip(label: "Main menu", action: { viewModel.goToRoot() })
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.offlineOptions) { node in
                            optionChip(label: node.label) {
                                viewModel.selectOption(node)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .background(Color.backgroundApp)
    }

    private func optionChip(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderLine, lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }

    // MARK: - Online Input Bar

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
