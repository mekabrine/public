import Foundation

struct ConversationTurn: Codable { let role: String; let text: String }
final class ConversationController {
    static let shared = ConversationController()
    private let queue = DispatchQueue(label: "com.uckermark.siriplus.conversation")
    private var history: [ConversationTurn] = []
    func reset() { queue.sync { history.removeAll() } }
    func transcript() -> [ConversationTurn] { queue.sync { history } }
    func append(role: String, text: String) {
        queue.sync {
            history.append(.init(role: role, text: text))
            let count = PreferenceManager.shared.value("contextLength", fallback: 10)
            if history.count > max(2, count * 2) { history.removeFirst(history.count - max(2, count * 2)) }
        }
    }
    func respond(to utterance: String) async throws -> String {
        append(role: "user", text: utterance)
        let preferences = PreferenceManager.shared.read()
        let backend = preferences["selectedBackend"] as? String ?? "Managed"
        let model: LLMAPI
        switch backend.lowercased() {
        case "chatgpt", "openai": model = ChatGPTAPI()
        case "gemini": model = GeminiAPI()
        default: model = ManagedAPI()
        }
        let prompt = preferences["customInstructions"] as? String ?? ""
        let transcript = transcript().map { ChatMessage(role: $0.role, content: $0.text) }
        let messages = prompt.isEmpty ? transcript : [ChatMessage(role: "system", content: prompt)] + transcript
        let response = try await model.complete(messages: messages, settings: preferences)
        append(role: "assistant", text: response)
        return response
    }
}
