import Foundation
import UIKit

/// Reconstructed Siri interception; not byte-equivalent to original Orion hook.
@objc(SiriInterceptBridge) final class SiriInterceptBridge: NSObject {
    private static let responseTag = 0x515149
    private static var generation: UInt64 = 0
    private static var lastUtterance = ""
    private static var lastRecognition = Date.distantPast
    private static let duplicateWindow: TimeInterval = 2.0
    @objc class func isEnabled() -> Bool {
        let values = PreferenceManager.shared.read()
        return (values["tweakEnabled"] as? Bool) ?? true
    }
    @objc class func consume(_ recognized: AnyObject?, controller: UIViewController) -> Bool {
        if !Thread.isMainThread {
            var consumed = false
            DispatchQueue.main.sync { consumed = consumeOnMain(recognized, controller: controller) }
            return consumed
        }
        return consumeOnMain(recognized, controller: controller)
    }
    private class func consumeOnMain(_ recognized: AnyObject?, controller: UIViewController) -> Bool {
        guard isEnabled(), let recognized = recognized else { return false }
        guard let utterance = extractSpeech(recognized), !utterance.isEmpty else { return false }
        let now = Date()
        if utterance == lastUtterance && now.timeIntervalSince(lastRecognition) < duplicateWindow { return true }
        lastUtterance = utterance
        lastRecognition = now
        generation &+= 1
        let sequence = generation
        Task { @MainActor in show("SiriPlus is thinking…", in: controller) }
        Task {
            do {
                let result = try await ConversationController.shared.respond(to: utterance)
                await MainActor.run {
                    guard sequence == generation else { return }
                    show(result, in: controller)
                }
            } catch {
                await MainActor.run {
                    guard sequence == generation else { return }
                    show("SiriPlus: \(error.localizedDescription)", in: controller)
                }
            }
        }
        return true
    }
    private class func extractSpeech(_ source: AnyObject) -> String? {
        if let plain = source as? String { return cleaned(plain) }
        if let words = safeGet(source, "text") as? String { return cleaned(words) }
        if let phrases = safeGet(source, "phrases") as? [AnyObject] {
            let matches = phrases.compactMap { phrase -> String? in
                if let s = phrase as? String { return s }
                return safeGet(phrase, "text") as? String
                    ?? safeGet(phrase, "value") as? String
            }
            if !matches.isEmpty { return cleaned(matches.joined(separator: " ")) }
        }
        if let interpretations = safeGet(source, "interpretations") as? [AnyObject] {
            for interpretation in interpretations {
                if let result = extractSpeech(interpretation), !result.isEmpty { return result }
            }
        }
        return nil
    }
    private class func cleaned(_ text: String) -> String? {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }
    private class func safeGet(_ object: AnyObject, _ key: String) -> Any? {
        if let dict = object as? [String: Any] { return dict[key] }
        guard let ns = object as? NSObject, ns.responds(to: NSSelectorFromString(key)) else { return nil }
        return ns.perform(NSSelectorFromString(key))?.takeUnretainedValue()
    }
    @MainActor private class func show(_ message: String, in controller: UIViewController) {
        guard controller.isViewLoaded else { return }
        let parent = controller.view!
        let container: UIView
        if let old = parent.viewWithTag(responseTag) { container = old }
        else {
            let box = UIView()
            box.tag = responseTag
            box.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.96)
            box.layer.cornerRadius = 16
            box.clipsToBounds = true
            box.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(box)
            NSLayoutConstraint.activate([
                box.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                box.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                box.bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor, constant: -24),
                box.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            ])
            let label = UILabel()
            label.tag = responseTag + 1
            label.numberOfLines = 0
            label.textColor = .label
            label.font = .preferredFont(forTextStyle: .body)
            label.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: box.topAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -16),
                label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16)
            ])
            container = box
        }
        (container.viewWithTag(responseTag + 1) as? UILabel)?.text = message
    }
}
