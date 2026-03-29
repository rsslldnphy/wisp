# Research: Polish and Cleanup

**Branch**: `006-polish-and-cleanup` | **Date**: 2026-03-29

---

## 1. NSSound Delegate for Play-Completion Callback

**Decision**: Use `NSSoundDelegate.sound(_:didFinishPlaying:)` to detect beep completion.

**Rationale**: `NSSound.play()` is asynchronous and returns immediately. The delegate callback `sound(_:didFinishPlaying:)` fires on the main thread when playback ends (or fails). This is the only supported mechanism to know when an NSSound has finished — there is no async/await alternative in AppKit for NSSound as of macOS 26. Storing a closure and firing it from the delegate is idiomatic.

**Alternatives considered**:
- **Fixed delay (e.g. `DispatchQueue.main.asyncAfter`)**: Fragile — depends on sound file duration staying constant; wastes time if the sound is short.
- **AVAudioPlayer with `audioPlayerDidFinishPlaying`**: Works but introduces a second audio framework dependency when NSSound is already used. Rejected per Simplicity principle.
- **Replace beep with silent lead-in**: Would change the user experience without fixing the root cause.

**Implementation note**: Set `sound.delegate = self` (or a dedicated helper object) before calling `play()`. The delegate object must be retained for the duration of playback.

---

## 2. SMAppService for Login Items (macOS 13+)

**Decision**: Use `SMAppService.mainApp` to register/unregister the app as a login item.

**Rationale**: `SMAppService` (introduced macOS 13, ServiceManagement framework) is the modern, sandboxing-compatible API for login items. It replaces the deprecated `SMLoginItemEnabled` and the `LaunchAgent` plist approach. The app's bundle identifier (`com.wisp.Wisp`) is already set; no helper app or bundle embedding is required for `mainApp` registration. The entitlements file does not need changes — `SMAppService` works within the existing sandbox.

**Status codes to handle**:
- `.enabled` — registered and will launch at login
- `.requiresApproval` — registered but waiting for user approval in System Settings (macOS 13 behaviour; should surface a prompt directing users to System Settings > General > Login Items)
- `.notFound` / `.notRegistered` — not registered
- Throws `SMAppServiceError` on failure

**Alternatives considered**:
- **`SMLoginItemEnabled`** (deprecated): Does not work for main app registration in modern macOS.
- **`LaunchAgent` plist in `~/Library/LaunchAgents`**: Not sandboxing-compatible without additional entitlements. Overly complex.
- **`ServiceManagement.framework` + helper bundle**: Unnecessary — `SMAppService.mainApp` registers the app itself without a helper.

**Sync on launch**: Compare `SMAppService.mainApp.status` with the stored `UserDefaults` value on startup and reconcile — the user may have toggled login items in System Settings between launches.

---

## 3. Template Image Rendering for Menu Bar Icons

**Decision**: Add the ghost icon as a PDF vector asset in `Assets.xcassets` with "Render As: Template Image".

**Rationale**: Template images are single-channel (alpha-only); macOS composites them with the appropriate tint colour automatically for light mode, dark mode, menu bar active/highlight states, and accessibility high-contrast mode. This is the standard approach for all NSStatusItem icons. Using PDF preserves sharpness at all resolutions (1x, 2x Retina, future densities).

**Required asset configuration**:
- Name: e.g. `StatusBarIcon`
- Type: PDF or SVG (Xcode 15+ supports SVG natively)
- Render As: Template Image (set in asset catalogue)
- Sizes: "Single Scale" is sufficient when using PDF/SVG

**Loading in code**:
```swift
let image = NSImage(named: "StatusBarIcon")
image?.isTemplate = true  // belt-and-suspenders; asset catalogue already sets this
statusItem.button?.image = image
```

**Alternatives considered**:
- **SF Symbol**: No existing "round ghost" in SF Symbols 5. Creating a custom SF Symbol is possible but requires the SF Symbols app and is harder to iterate on visually.
- **PNG @1x/@2x**: Works but resolution-dependent. PDF/SVG is strictly better.

---

## 4. Beep-Recording Timing Root Cause Confirmation

**Root cause confirmed**: In `AppDelegate.swift`, the call sequence is:

```swift
menuBarController?.playStartSound()   // fires NSSound.play() — returns immediately
// ... a few more synchronous lines ...
audioCaptureService?.startRecording(autoStopHandler:)  // installs AVAudioEngine tap
```

`NSSound.play()` returns before the beep has played. The `AVAudioEngine` tap is installed almost simultaneously, meaning the first audio frames captured by the microphone overlap with the tail of the beep being played through the speakers. On macs with minimal speaker-microphone isolation (MacBook built-in speakers) this causes the beep to be picked up.

**Fix**: Gate `startRecording` on the `NSSoundDelegate` callback. The `record-start.wav` asset duration determines the actual delay — typically 0.2–0.5 s. No artificial sleep or hardcoded delay is needed.

**Fallback timer**: If `didFinishPlaying` does not fire within 1000 ms (sound file missing, delegate not set, etc.), fall back to starting recording unconditionally, preserving existing behaviour.
