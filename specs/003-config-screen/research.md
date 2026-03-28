# Research: Configuration Screen

**Branch**: `003-config-screen` | **Date**: 2026-03-28

## Decision 1: Keyboard Shortcut Recording & Persistence

**Decision**: Re-add the `KeyboardShortcuts` library (Sindre Sorhus, v2.x) to `Package.swift` and use it as the sole mechanism for shortcut registration, recording, and persistence.

**Rationale**: The library was already a declared dependency (present in `.build/checkouts/`) and is referenced in the CLAUDE.md active technologies list. It provides a `KeyboardShortcuts.Recorder` SwiftUI component for in-UI capture, automatic `UserDefaults` persistence keyed by a typed `Name` enum, and built-in blocking of macOS system-reserved shortcuts — which directly satisfies FR-003 and FR-004 without custom implementation. The existing `HotkeyService` hardcodes `keyCode == 49` (Space) + `.maskAlternate`; replacing this check with `KeyboardShortcuts.onKeyDown(for: .toggleDictation)` removes the hardcoded value and delegates shortcut management entirely to the library.

**Alternatives considered**:
- *Keep CGEventTap + custom capture view*: Would require building a key-capture `NSView`/`NSTextField` subclass, manual `UserDefaults` serialisation of key codes and modifier flags, and custom system-shortcut conflict detection. Duplicates what KeyboardShortcuts already provides reliably.
- *Carbon `RegisterEventHotKey`*: Deprecated path, does not support all modifier combinations, no built-in UI component.

**Integration note**: `HotkeyService.startListening()` currently calls `CGEvent.tapCreate` and inspects raw key codes. After this change it will call `KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in self?.onToggle() }`. The `CGEvent.tapCreate` infrastructure can be removed entirely; the library manages its own event tap.

---

## Decision 2: Microphone Enumeration & Hot-Plug

**Decision**: Use CoreAudio `AudioObjectGetPropertyData` with `kAudioHardwarePropertyDevices` to enumerate input-capable devices. Register a `AudioObjectAddPropertyListener` on `kAudioObjectSystemObject` for `kAudioHardwarePropertyDevices` to detect hot-plug events and refresh the device list in the UI automatically.

**Rationale**: On macOS, `AVCaptureDevice.DiscoverySession` targets camera/microphone capture sessions and requires a running `AVCaptureSession` — heavyweight for an enumeration-only use case. CoreAudio property queries are lightweight, synchronous, and the canonical macOS approach for audio device management. The `kAudioDevicePropertyScopeInput` stream configuration check filters to input-capable devices only.

**Device identification for persistence**: CoreAudio provides a stable `kAudioDevicePropertyDeviceUID` string (e.g., `"AppleUSBAudioEngine:Apple Inc.:USB-C to 3.5mm Headphone Jack Adapter:..."`) that persists across reboots and reconnects. This UID is stored in `UserDefaults` as the `selectedMicrophoneUID` key.

**Device switching in AVAudioEngine**: `AVAudioEngine.inputNode` exposes an underlying `AudioUnit`. Setting `kAudioOutputUnitProperty_CurrentDevice` on that AudioUnit (scope `kAudioUnitScope_Global`, element 0) switches the physical input device. This must be done before or after `AVAudioEngine.start()` but requires stopping and restarting the engine when called while recording is active. Since the microphone is only changeable via the config screen (not during active dictation), the engine will always be stopped at the time of device switch.

**Alternatives considered**:
- *AVCaptureDevice.DiscoverySession*: Simpler API surface but requires a live AVCaptureSession and does not provide the stable UID needed for persistence. Discarded.
- *AVAudioSession (iOS API)*: Not available on macOS. N/A.

---

## Decision 3: Preferences Persistence

**Decision**: `UserDefaults.standard` wrapped in a Swift `actor PreferencesStore`. Two explicit keys: `com.wisp.selectedMicrophoneUID` (optional String) and `com.wisp.cleanupPrompt` (String, defaults to the current hardcoded prompt text). The hotkey is persisted automatically by the `KeyboardShortcuts` library under its own key.

**Rationale**: The three config values are small, scalar, and non-sensitive — exactly the use case `UserDefaults` is designed for. An actor wrapper enforces Swift 6.2 strict concurrency requirements and provides a single synchronisation point for all reads and writes. File-based JSON in `~/Library/Application Support/` would be appropriate for larger structured configuration but adds unnecessary serialisation complexity here.

**Default values**:
- `selectedMicrophoneUID`: `nil` — means "use system default input device" (AudioCaptureService falls back to `AVAudioEngine`'s default input when nil)
- `cleanupPrompt`: the exact multi-line string currently hardcoded in `TextCleanupService.swift`
- Hotkey: `Option+Space` registered as the library default via `KeyboardShortcuts.Name.toggleDictation`

**Reset-to-default behaviour**: `PreferencesStore.resetCleanupPrompt()` writes the default string back. `PreferencesStore.resetMicrophone()` writes `nil`. Hotkey reset calls `KeyboardShortcuts.reset(.toggleDictation)`.

**Alternatives considered**:
- *CoreData*: Substantial overhead for three scalar values. Rejected.
- *File-based JSON*: Appropriate for structured/versioned config but over-engineered here. Deferred to a future feature if config grows.
- *`@AppStorage` in SwiftUI view directly*: Bypasses the actor and scatters persistence logic across the view layer. Rejected to keep the `PreferencesStore` as the single source of truth.

---

## Decision 4: Config UI Framework & Window Pattern

**Decision**: SwiftUI `PreferencesView` hosted inside a standard `NSWindow` managed by an `NSWindowController` subclass (`PreferencesWindow`). Opened via a "Preferences…" `NSMenuItem` in the existing status bar menu.

**Rationale**: The Wisp constitution explicitly permits SwiftUI for settings/preferences panels. SwiftUI's `Form` and `Section` layout maps naturally to the three-section config screen. `NSWindowController` provides standard macOS window lifecycle (single instance, `showWindow(_:)`, `close()`). Using `NSWindow` directly (rather than `SwiftUI.WindowGroup`) avoids App Store/SwiftUI lifecycle requirements that conflict with the LSUIElement background-app pattern.

**Shortcut recorder integration**: `KeyboardShortcuts.Recorder("Toggle Dictation", name: .toggleDictation)` is a SwiftUI `View` that can be dropped directly into the `Form`.

**Alternatives considered**:
- *`NSPreferencesWindowController` / `NSTabViewController`*: AppKit-native but more verbose; no benefit here given SwiftUI is permitted and the panel has no tabs.
- *`SwiftUI.Settings` scene*: Requires `@main App` with `Settings {}` scene block, incompatible with the existing `WispApp.swift` `NSApplication`-based entry point. Rejected.
- *`NSPopover` from the status bar icon*: Too constrained for a text-area editor (cleanup prompt). Rejected.

---

## Decision 5: System Shortcut Conflict Detection

**Decision**: Rely entirely on the `KeyboardShortcuts` library's built-in conflict detection. The `Recorder` view automatically disables recording of macOS system-reserved combinations and displays an inline error if the user attempts one.

**Rationale**: The clarification in Session 2026-03-28 (Q2) scoped conflict detection to system-reserved shortcuts only, explicitly excluding third-party app detection. The `KeyboardShortcuts` library implements exactly this scope — it checks against the system's list of reserved shortcuts before accepting a recording. No custom implementation needed.

**Alternatives considered**:
- *Custom CGEventTap scan for blocked shortcuts*: Redundant; the library already does this.
- *Third-party conflict detection via `NSWorkspace` running apps scan*: Out of scope per clarification Q2. Rejected.
