import Foundation
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date

    init(content: String, isFromUser: Bool) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}

class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(
            content: "Hi! I'm UniRide assistant. Ask me anything about your commute, traffic, or available rides.",
            isFromUser: false
        )
    ]
    @Published var isLoading = false

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(content: trimmed, isFromUser: true))
        isLoading = true

        CloudFunctionsService.shared.chatbot(message: trimmed) { [weak self] reply in
            DispatchQueue.main.async {
                self?.isLoading = false
                let response = reply ?? "Sorry, I couldn't connect right now. Please try again."
                self?.messages.append(ChatMessage(content: response, isFromUser: false))
            }
        }
    }
}
