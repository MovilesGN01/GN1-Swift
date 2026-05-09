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
            content: "Hi! I'm UniRide Assistant. Ask me anything about your commute, traffic, or available rides.",
            isFromUser: false
        )
    ]
    @Published var isLoading = false

    // MARK: - Offline state

    /// True when the last AI call failed — switches UI to decision-tree mode.
    @Published var isOffline = false

    /// Options shown at the current tree level.
    @Published var offlineOptions: [OfflineNode] = []

    /// True while the offline data context is being loaded from CoreData.
    @Published var isLoadingContext = false

    /// Breadcrumb stack for back-navigation.
    private var nodeStack: [OfflineNode] = []

    /// Real user data loaded from CoreData — powers dynamic nodes.
    private var offlineContext: OfflineDataContext?

    var canGoBack: Bool { !nodeStack.isEmpty }

    // MARK: - Online send

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(content: trimmed, isFromUser: true))
        isLoading = true

        CloudFunctionsService.shared.chatbot(message: trimmed) { [weak self] reply in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                if let reply {
                    self.isOffline = false
                    self.messages.append(ChatMessage(content: reply, isFromUser: false))
                } else {
                    self.enterOfflineMode()
                }
            }
        }
    }

    // MARK: - Offline tree navigation

    func selectOption(_ node: OfflineNode) {
        messages.append(ChatMessage(content: node.label, isFromUser: true))
        let response = node.response(context: offlineContext)
        messages.append(ChatMessage(content: response, isFromUser: false))

        if node.isLeaf {
            offlineOptions = []
        } else {
            nodeStack.append(node)
            offlineOptions = node.children
        }
    }

    func goBack() {
        guard !nodeStack.isEmpty else { return }
        nodeStack.removeLast()
        offlineOptions = nodeStack.isEmpty
            ? OfflineChatTree.root.children
            : nodeStack.last!.children
    }

    func goToRoot() {
        nodeStack.removeAll()
        offlineOptions = OfflineChatTree.root.children
        messages.append(ChatMessage(content: "What else can I help you with?", isFromUser: false))
    }

    func retryOnline() {
        isOffline = false
        offlineOptions = []
        nodeStack.removeAll()
        messages.append(ChatMessage(
            content: "Trying to reconnect… Type your question and I'll do my best!",
            isFromUser: false
        ))
    }

    // MARK: - Private

    private func enterOfflineMode() {
        guard !isOffline else { return }
        isOffline = true
        nodeStack.removeAll()
        offlineOptions = OfflineChatTree.root.children

        // Load CoreData context in background, then update the greeting
        guard let userId = UserSession.shared.userId else {
            messages.append(ChatMessage(
                content: "I can't reach the server right now. " +
                         "Here are some topics I can help you with offline:",
                isFromUser: false
            ))
            return
        }

        isLoadingContext = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            let ctx = await OfflineDataContext.load(userId: userId)
            self.offlineContext = ctx
            self.isLoadingContext = false

            // Greet with a summary of what real data is available
            let summary = ctx.summaryResponse()
            self.messages.append(ChatMessage(
                content: "I can't reach the server right now. \(summary)\n\n" +
                         "Tap a topic below or choose My Data to see your cached rides and requests.",
                isFromUser: false
            ))
        }
    }
}
