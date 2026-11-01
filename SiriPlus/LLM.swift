import Foundation

struct ChatMessage: Codable { let role: String; let content: String }
enum APIError: Error { case badURL, badResponse, missingKey, noContent }
protocol LLMAPI {
    func complete(messages: [ChatMessage], settings: [String: Any]) async throws -> String
}
private func postJSON(url: URL, token: String?, payload: [String: Any]) async throws -> [String: Any] {
    var req = URLRequest(url: url); req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token, !token.isEmpty { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    req.httpBody = try JSONSerialization.data(withJSONObject: payload)
    let (data, response) = try await URLSession.shared.data(for: req)
    guard (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) == true else { throw APIError.badResponse }
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}
struct ChatGPTAPI: LLMAPI {
    func complete(messages: [ChatMessage], settings: [String: Any]) async throws -> String {
        let key = settings["gptKey"] as? String ?? settings["apiKey"] as? String ?? ""
        guard !key.isEmpty else { throw APIError.missingKey }
        let base = settings["gptBaseURL"] as? String ?? "https://api.openai.com/v1"
        guard let url = URL(string: base.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions") else { throw APIError.badURL }
        let payload: [String: Any] = ["model": settings["gptModel"] as? String ?? "gpt-4o-mini", "messages": messages.map { ["role": $0.role, "content": $0.content] }, "temperature": settings["temperature"] as? Double ?? 0.7]
        let result = try await postJSON(url: url, token: key, payload: payload)
        guard let choices = result["choices"] as? [[String: Any]], let message = choices.first?["message"] as? [String: Any], let content = message["content"] as? String else { throw APIError.noContent }
        return content
    }
}
struct GeminiAPI: LLMAPI {
    func complete(messages: [ChatMessage], settings: [String: Any]) async throws -> String {
        let key = settings["geminiKey"] as? String ?? settings["apiKey"] as? String ?? ""
        guard !key.isEmpty else { throw APIError.missingKey }
        let model = settings["geminiModel"] as? String ?? "gemini-2.0-flash"
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)") else { throw APIError.badURL }
        let contents = messages.filter { $0.role != "system" }.map { ["role": $0.role == "assistant" ? "model" : "user", "parts": [["text": $0.content]]] as [String: Any] }
        let result = try await postJSON(url: url, token: nil, payload: ["contents": contents])
        let candidates = result["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let text = parts?.compactMap({ $0["text"] as? String }).joined(separator: "\n"), !text.isEmpty else { throw APIError.noContent }
        return text
    }
}
struct ManagedAPI: LLMAPI {
    func complete(messages: [ChatMessage], settings: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://siriplus.uckermark.dev/v1/chat/completions") else { throw APIError.badURL }
        let result = try await postJSON(url: url, token: nil, payload: ["messages": messages.map { ["role": $0.role, "content": $0.content] }])
        let choices = result["choices"] as? [[String: Any]]
        let msg = choices?.first?["message"] as? [String: Any]
        guard let content = msg?["content"] as? String else { throw APIError.noContent }
        return content
    }
}
