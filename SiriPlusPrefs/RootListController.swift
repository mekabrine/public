import Foundation
import UIKit
import SwiftUI
import Preferences

// Reconstructed settings structure, not original source.
final class RootListController: PSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SiriPlus"
        let host = UIHostingController(rootView: SiriPlusSettingsView())
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }
}
struct SiriPlusSettingsView: View {
    @State private var enabled = false
    @State private var copyUI = false
    @State private var backend = "Managed"
    @State private var selectedAI = "ChatGPT"
    @State private var apiKey = ""
    @State private var instructions = ""
    @State private var context = 10.0
    private let domain = "com.uckermark.siriplus"
    private func load() {
        let values = NSDictionary(contentsOfFile: "/var/mobile/Library/Preferences/\(domain).plist") as? [String: Any] ?? [:]
        enabled = values["tweakEnabled"] as? Bool ?? false
        copyUI = values["copyButtonEnabled"] as? Bool ?? false
        backend = values["selectedBackend"] as? String ?? "Managed"
        selectedAI = values["selectedAI"] as? String ?? "ChatGPT"
        apiKey = values["apiKey"] as? String ?? ""
        context = (values["contextLength"] as? NSNumber)?.doubleValue ?? 10
        instructions = values["customInstructions"] as? String ?? ""
    }
    private func save(_ key: String, _ value: Any) {
        let path = "/var/mobile/Library/Preferences/\(domain).plist"
        var dict = NSDictionary(contentsOfFile: path) as? [String: Any] ?? [:]
        dict[key] = value
        (dict as NSDictionary).write(toFile: path, atomically: true)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(domain as CFString), nil, nil, true)
    }
    var body: some View {
        Form {
            Section("SiriPlus") {
                Toggle("Enable SiriPlus", isOn: $enabled).onChange(of: enabled) { save("tweakEnabled", $0) }
                Toggle("CopyUI", isOn: $copyUI).onChange(of: copyUI) { save("copyButtonEnabled", $0) }
                Picker("Backend", selection: $backend) { ForEach(["Managed", "ChatGPT", "Gemini"], id: \.self) { Text($0) } }.onChange(of: backend) { save("selectedBackend", $0) }
                Picker("AI", selection: $selectedAI) { ForEach(["ChatGPT", "Gemini"], id: \.self) { Text($0) } }.onChange(of: selectedAI) { save("selectedAI", $0) }
                SecureField("API Key", text: $apiKey).onChange(of: apiKey) { save("apiKey", $0) }
                TextField("Custom instructions", text: $instructions).onChange(of: instructions) { save("customInstructions", $0) }
            }
            Section("Conversation") {
                Text("Context length: \(Int(context))")
                Slider(value: $context, in: 1...30, step: 1).onChange(of: context) { save("contextLength", Int($0)) }
                Button("Reset chat context") { CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName("com.uckermark.siriplus/reset" as CFString), nil, nil, true) }
            }
            Section("Functions") {
                ForEach(["webBrowsingAllowed", "sendMailAllowed", "sysInfoAllowed", "calendarEntryAllowed", "phoneCallAllowed", "openMapsAllowed", "openAppsAllowed", "pasteboardAllowed"], id: \.self) { key in
                    FunctionToggle(key: key, save: save)
                }
            }
        }.onAppear(perform: load)
    }
}
struct FunctionToggle: View {
    let key: String
    let save: (String, Any) -> Void
    @State private var isOn = false
    var body: some View {
        Toggle(key.replacingOccurrences(of: "Allowed", with: ""), isOn: $isOn)
            .onAppear { isOn = (NSDictionary(contentsOfFile: "/var/mobile/Library/Preferences/com.uckermark.siriplus.plist") as? [String: Any])?[key] as? Bool ?? false }
            .onChange(of: isOn) { save(key, $0) }
    }
}
