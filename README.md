# SiriPlus 1.4 — reconstructed source (unverified)

Recovered from the owner's rootless jailbreak tweak package. This is a **best-effort, incomplete reconstruction**, not the original source and not a proven drop-in replacement.

### Structure
- `SiriPlus/SiriHooks.x` — Logos hooks for Siri recognition and command handler.
- `SiriPlus/SiriInterceptBridge.swift` — defensive text extraction, conversation dispatch, and temporary overlay.
- `SiriPlus/LLM.swift` — inferred ChatGPT/Gemini/managed API clients.
- `SiriPlus/Conversation.swift` — inferred history controller and routing.
- `SiriPlus/Actions.swift`, `Web.swift` — inferred action handlers.
- `SiriPlus/Settings.swift` — reconstructed preference manager.
- `SiriPlusPrefs/RootListController.swift` — reconstructed SwiftUI settings (not wired into Makefile).
- `SiriPlusCC/SiriPlusCC.m` — Control Center toggle.
- `Makefile` — Theos rootless scaffold.

**Important:** Siri command suppression and the original response-presentation mechanism are not recovered. The speech hook calls `%orig`, and normal Siri may also respond. This project has not been compiled or validated on a device.

See [RECOVERY_AUDIT.md](RECOVERY_AUDIT.md).

To retrieve the source without ChatGPT downloads, use GitHub's **Code → Download ZIP** option on this repository.
