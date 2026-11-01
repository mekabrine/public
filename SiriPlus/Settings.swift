import Foundation

struct Settings: Codable {
    var aiModel = ""
    var tweakEnabled = true
    var copyButtonEnabled = false
    var apiKey = ""
    var gptKey = ""
    var geminiKey = ""
    var customInstructions = ""
    var contextLength = 10
    var temperature = 0.7
    var selectedBackend = "Managed"
    var selectedAI = "ChatGPT"
    var gptModel = ""
    var gptBaseURL = "https://api.openai.com/v1"
    var geminiModel = "gemini-2.0-flash"
    var webBrowsingAllowed = false
    var sendMailAllowed = false
    var sysInfoAllowed = false
    var calendarEntryAllowed = false
    var phoneCallAllowed = false
    var openMapsAllowed = false
    var openAppsAllowed = false
    var pasteboardAllowed = false
}

final class PreferenceManager {
    static let shared = PreferenceManager()
    static let domain = "com.uckermark.siriplus"
    static let path = "/var/mobile/Library/Preferences/\(domain).plist"
    private init() {}
    func read() -> [String: Any] { NSDictionary(contentsOfFile: Self.path) as? [String: Any] ?? [:] }
    func value<T>(_ key: String, fallback: T) -> T { read()[key] as? T ?? fallback }
    func save(_ key: String, value: Any) {
        var dict = read(); dict[key] = value
        (dict as NSDictionary).write(toFile: Self.path, atomically: true)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.domain as CFString), nil, nil, true)
    }
}
