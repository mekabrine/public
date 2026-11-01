import Foundation
import UIKit

enum SiriPlusFunctions {
    static func deviceInfo() -> String {
        let d = UIDevice.current; d.isBatteryMonitoringEnabled = true
        return "Battery State: \(d.batteryState.rawValue), Battery Level: \(Int(d.batteryLevel * 100))%, System Version: \(d.systemVersion), Model: \(d.model)"
    }
    static func copyToPasteboard(_ text: String) { UIPasteboard.general.string = text }
    static func getTextFromPasteboard() -> String? { UIPasteboard.general.string }
    static func openMaps(_ query: String) {
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?q=" + escaped) else { return }
        UIApplication.shared.open(url)
    }
    static func searchWeb(_ query: String) async throws -> Data {
        var parts = URLComponents(string: "https://siriplus.uckermark.dev/search")!
        parts.queryItems = [URLQueryItem(name: "q", value: query)]
        return try await URLSession.shared.data(from: parts.url!).0
    }
}
