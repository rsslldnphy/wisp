# Quickstart: Configuration Screen

**Branch**: `003-config-screen` | **Date**: 2026-03-28

## Prerequisites

- macOS 26+, Xcode 26 (Swift 6.2 toolchain)
- Wisp builds and runs (existing feature 001 and 002 complete)

## Step 1 — Add KeyboardShortcuts dependency

In `Package.swift`, add to `dependencies`:
```swift
.package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "2.0.0"),
```
Wait — the correct package is KeyboardShortcuts by Sindre Sorhus:
```swift
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
```
And to the `Wisp` target's `dependencies` array:
```swift
.product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
```
Run `swift package resolve` to fetch.

## Step 2 — Define the shortcut name

Add to a new file `Wisp/Models/ShortcutNames.swift` (or alongside `PreferencesStore`):
```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleDictation = Self("toggleDictation", default: .init(.space, modifiers: .option))
}
```

## Step 3 — Create PreferencesStore

Create `Wisp/Models/PreferencesStore.swift` implementing the actor API in [contracts/preferences-store.md](contracts/preferences-store.md). Write `PreferencesStoreTests` first (red), then implement (green).

Key UserDefaults keys:
```swift
private enum Keys {
    static let cleanupPrompt = "com.wisp.cleanupPrompt"
    static let selectedMicrophoneUID = "com.wisp.selectedMicrophoneUID"
}
```

## Step 4 — Update existing services

**HotkeyService**: Remove `CGEvent.tapCreate` key-check logic. Replace `startListening()` body with:
```swift
KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in
    self?.onToggle()
}
```
Remove Accessibility permission request from HotkeyService (KeyboardShortcuts handles it).

**TextCleanupService**: Add `init(preferences: PreferencesStore)`. In `clean(_ text: String)`, replace the hardcoded prompt with:
```swift
let prompt = await preferences.cleanupPrompt + "\n\nTranscribed text: \(text)"
```

**AudioCaptureService**: Add `init(preferences: PreferencesStore)`. Before `engine.start()` in `startRecording()`, read `await preferences.selectedMicrophoneUID` and call the CoreAudio device-switch helper if non-nil.

## Step 5 — Build MicrophoneList actor

Create a `MicrophoneList` actor that:
1. Enumerates CoreAudio devices with input streams on `init`
2. Registers `AudioObjectAddPropertyListener` on `kAudioObjectSystemObject` / `kAudioHardwarePropertyDevices` for hot-plug
3. Publishes `devices: [MicrophoneDevice]` updates via `AsyncStream` or `@Observable`

See [data-model.md](data-model.md) for entity definitions.

## Step 6 — Build PreferencesView + PreferencesWindow

Create `Wisp/UI/PreferencesView.swift` (SwiftUI `Form` with three sections per [contracts/config-ui.md](contracts/config-ui.md)) and `Wisp/UI/PreferencesWindow.swift` (`NSWindowController` hosting the view).

## Step 7 — Wire into AppDelegate

1. Instantiate `PreferencesStore` in `applicationDidFinishLaunching`
2. Inject into `AudioCaptureService`, `TextCleanupService` (replace hardcoded construction)
3. Add "Preferences…" `NSMenuItem` to the status bar menu above "Quit Wisp"
4. On menu item action: call `PreferencesWindow.shared.showWindow(nil)`

## Verification

1. Launch app → "Preferences…" appears in status bar menu
2. Open preferences → three sections visible
3. Change shortcut → old shortcut stops working, new shortcut triggers dictation
4. Select a different microphone → next dictation session uses it
5. Edit prompt, save, dictate → output reflects new prompt
6. Clear prompt → inline error shown, previous prompt still active
7. Reset prompt → default text restored
8. Disconnect microphone while preferences open → list updates immediately
