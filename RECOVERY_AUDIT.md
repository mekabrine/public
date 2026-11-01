# SiriPlus 1.4 recovery audit

## Confirmed from compiled package
- Original tweak Mach-O contains arm64 and arm64e.
- Swift names include AFUISiriViewControllerHook, AFConnectionHook, ObjCBridge and backend classes.
- Private selectors include _tellSpeechDelegateSpeechRecognized: and _handleCommand:reply:.

## Reconstructed / unverified
- Logos speech hook with selector existence checks.
- Swift bridge for recognized text, dispatch, temporary overlay, and duplicate suppression.
- Settings, conversation controller, API clients, and action handlers.

## Gaps
- Hook calls %orig, so native Siri may act on the utterance.
- AFConnection hook currently passes through commands.
- Original Siri-native response flow and suppression not recovered.
- Original API, authorization, and function-calling protocols not confirmed.
- Preferences bundle not wired into provided Makefile.
- No Theos build or jailbroken-device verification.

This is source-level reverse engineering, not a fully recovered or byte-identical original.
