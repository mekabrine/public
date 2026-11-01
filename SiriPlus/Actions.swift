import Foundation
import UIKit
import Contacts
import EventKit

// Reconstructed from selector and function strings; argument schemas are inferred.
struct ToolCall: Codable { var id: String; var name: String; var arguments: [String: String] }
struct ToolResult: Codable { var id: String; var name: String; var result: String }
final class ActionDispatcher {
    static let shared = ActionDispatcher()
    private let contacts = CNContactStore()
    private let events = EKEventStore()
    private var settings: [String: Any] { PreferenceManager.shared.read() }
    private func permitted(_ key: String) -> Bool { settings[key] as? Bool == true }
    enum ActionError: LocalizedError {
        case disabled(String), missing(String), unsupported(String)
        var errorDescription: String? {
            switch self {
            case .disabled(let name): return "Function disabled: \(name)"
            case .missing(let name): return "Failed to extract \(name)"
            case .unsupported(let name): return "Unknown function called: \(name)"
            }
        }
    }
    func dispatch(_ call: ToolCall) async -> ToolResult {
        do { return ToolResult(id: call.id, name: call.name, result: try await execute(call)) }
        catch { return ToolResult(id: call.id, name: call.name, result: error.localizedDescription) }
    }
    private func required(_ name: String, from args: [String:String]) throws -> String {
        guard let text = args[name], !text.isEmpty else { throw ActionError.missing(name) }
        return text
    }
    private func execute(_ call: ToolCall) async throws -> String {
        let a = call.arguments
        switch call.name {
        case "get_text_from_pasteboard":
            guard permitted("pasteboardAllowed") else { throw ActionError.disabled(call.name) }
            return UIPasteboard.general.string ?? ""
        case "copy_to_pasteboard":
            guard permitted("pasteboardAllowed") else { throw ActionError.disabled(call.name) }
            UIPasteboard.general.string = try required("text", from: a)
            return "Text copied to pasteboard"
        case "get_system_info", "system_info":
            guard permitted("sysInfoAllowed") else { throw ActionError.disabled(call.name) }
            return SiriPlusFunctions.deviceInfo()
        case "open_maps":
            guard permitted("openMapsAllowed") else { throw ActionError.disabled(call.name) }
            let destination = try required("destination", from: a)
            await MainActor.run { SiriPlusFunctions.openMaps(destination) }
            return "Opened Maps"
        case "open_app":
            guard permitted("openAppsAllowed") else { throw ActionError.disabled(call.name) }
            let bundle = try required("bundleID", from: a)
            guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
                  let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject else {
                return "Failed to get LSApplicationWorkspace while trying to open \(bundle)"
            }
            let sel = NSSelectorFromString("openApplicationWithBundleID:")
            let opened = workspace.perform(sel, with: bundle)?.takeUnretainedValue()
            return opened == nil ? "Failed to open app: \(bundle)" : "Opened \(bundle)"
        case "get_contacts":
            guard permitted("phoneCallAllowed") || permitted("sendMailAllowed") else { throw ActionError.disabled(call.name) }
            let name = try required("name", from: a)
            let matches = try findContacts(name)
            return matches.map { "\($0.givenName) \($0.familyName): \($0.phoneNumbers.map(\.value.stringValue).joined(separator: ", "))" }.joined(separator: "\n")
        case "call":
            guard permitted("phoneCallAllowed") else { throw ActionError.disabled(call.name) }
            let matches = try findContacts(try required("name", from: a))
            guard matches.count == 1, let number = matches[0].phoneNumbers.first?.value.stringValue else {
                return "Failed: No phone number found for \(a["name"] ?? "contact")"
            }
            let digits = number.filter { $0.isNumber || $0 == "+" }
            guard let url = URL(string: "tel:" + digits) else { throw ActionError.missing("number") }
            await MainActor.run { UIApplication.shared.open(url) }
            return "Call requested"
        case "add_calendar":
            guard permitted("calendarEntryAllowed") else { throw ActionError.disabled(call.name) }
            let title = try required("title", from: a)
            let formatter = DateFormatter(); formatter.dateFormat = "MM/dd/yy HH:mm"
            guard let start = formatter.date(from: try required("start", from: a)),
                  let end = formatter.date(from: try required("end", from: a)) else { return "Got invalid date format (MM/dd/yy HH:mm)" }
            let granted: Bool = try await withCheckedThrowingContinuation { continuation in
                events.requestAccess(to: .event) { allowed, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: allowed) }
                }
            }
            guard granted else { return "CalendarError: Access denied" }
            let event = EKEvent(eventStore: events); event.title = title
            event.startDate = start; event.endDate = end; event.calendar = events.defaultCalendarForNewEvents
            try events.save(event, span: .thisEvent)
            return "Event added to calendar"
        case "send_mail":
            guard permitted("sendMailAllowed") else { throw ActionError.disabled(call.name) }
            let address = try required("mail", from: a)
            let subject = (a["subject"] ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = (a["body"] ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "mailto:\(address)?subject=\(subject)&body=\(body)") else { throw ActionError.missing("mail") }
            await MainActor.run { UIApplication.shared.open(url) }
            return "Mail composer opened"
        case "search_web":
            guard permitted("webBrowsingAllowed") else { throw ActionError.disabled(call.name) }
            let data = try await SiriPlusFunctions.searchWeb(try required("query", from: a))
            return String(data: data, encoding: .utf8) ?? "No results found"
        default: throw ActionError.unsupported(call.name)
        }
    }
    private func findContacts(_ name: String) throws -> [CNContact] {
        let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor])
        let needle = name.lowercased()
        var results: [CNContact] = []
        try contacts.enumerateContacts(with: request) { contact, stop in
            let full = "\(contact.givenName) \(contact.familyName)".lowercased()
            if full.contains(needle) { results.append(contact) }
        }
        return results
    }
}
