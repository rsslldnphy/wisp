# Implementation Plan: Configuration Screen

**Branch**: `003-config-screen` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-config-screen/spec.md`

## Summary

Add a preferences panel (SwiftUI wrapped in `NSWindowController`) that exposes three user-configurable settings: the global keyboard shortcut for recording, the active audio input device, and the LLM transcription cleanup prompt. All settings are persisted via `UserDefaults` and take effect immediately for subsequent dictation sessions without restarting the app. The `KeyboardShortcuts` library (Sindre Sorhus) is added back to `Package.swift` and replaces the current hardcoded CGEventTap key check; CoreAudio APIs handle microphone enumeration and live hot-plug refresh.

## Technical Context

**Language/Version**: Swift 6.2 with strict concurrency checking enabled
**Primary Dependencies**: WhisperKit (existing), KeyboardShortcuts 2.x (Sindre Sorhus — re-add to Package.swift), AVFoundation (existing), CoreAudio (system framework), Apple FoundationModels (existing), AppKit + SwiftUI
**Storage**: UserDefaults — two explicit keys (`selectedMicrophoneUID`, `cleanupPrompt`); hotkey managed automatically by KeyboardShortcuts library
**Testing**: XCTest (existing)
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: Desktop background app (LSUIElement)
**Performance Goals**: Config screen has no audio-path involvement; UserDefaults reads/writes are negligible
**Constraints**: All processing remains on-device; no network calls introduced; config changes must take effect without app restart
**Scale/Scope**: Three persisted settings per user; microphone list bounded by connected devices (typically 1–5)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Privacy-First Local Processing** — ✅ Pass. Stores only microphone UID and prompt text in UserDefaults. No network calls. No audio data leaves device.
- **II. Type Safety & Correctness** — ✅ Pass. `PreferencesStore` will be an `actor`. All new public APIs have explicit types. No force-unwraps.
- **III. Test-First Development** — ✅ Pass. PreferencesStore persistence, device enumeration, and empty-state handling each require happy-path + failure-mode XCTest coverage before implementation.
- **IV. Performance-Conscious Design** — ✅ Pass. Config screen is off the audio hot path. Device list refresh uses CoreAudio notification callbacks, not polling.
- **V. Simplicity & YAGNI** — ✅ Pass. Exactly three settings. No plugin system, cloud sync, or scripting. KeyboardShortcuts was a prior dependency; re-adding it is not speculative.

*Post-Phase 1 re-check*: No violations introduced. SwiftUI settings panel is explicitly permitted by the constitution. CoreAudio usage has no hot-path implications.

## Project Structure

### Documentation (this feature)

```text
specs/003-config-screen/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── preferences-store.md   # PreferencesStore actor API contract
│   └── config-ui.md           # UI layout and validation behaviour contract
└── tasks.md             # Phase 2 output (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
Wisp/
├── App/
│   └── AppDelegate.swift           # Modify: add "Preferences…" menu item; inject PreferencesStore into services; open PreferencesWindow on demand
├── Models/
│   └── PreferencesStore.swift      # New: actor persisting all config values via UserDefaults
├── Services/
│   ├── AudioCaptureService.swift   # Modify: accept optional device UID; switch CoreAudio input device before engine start
│   ├── HotkeyService.swift         # Modify: replace hardcoded keyCode check with KeyboardShortcuts library onKeyDown callback
│   └── TextCleanupService.swift    # Modify: read prompt from PreferencesStore instead of hardcoded literal
└── UI/
    ├── PreferencesWindow.swift     # New: NSWindowController that hosts the SwiftUI PreferencesView
    └── PreferencesView.swift       # New: SwiftUI view with shortcut recorder, microphone picker, prompt editor

Package.swift                       # Modify: add KeyboardShortcuts dependency

WispTests/
└── Unit/
    ├── PreferencesStoreTests.swift        # New: persistence, defaults, reset-to-default, empty-prompt guard
    └── MicrophoneEnumerationTests.swift   # New: device list, hot-plug, no-devices state
```

**Structure Decision**: Single-project layout (existing pattern). No new modules or targets introduced. New files placed alongside existing counterparts in `Models/`, `Services/`, and `UI/`.
