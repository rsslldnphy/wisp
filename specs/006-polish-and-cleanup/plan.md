# Implementation Plan: Polish and Cleanup

**Branch**: `006-polish-and-cleanup` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-polish-and-cleanup/spec.md`

## Summary

Three independent polish items before 1.0:
1. Replace the placeholder SF Symbol menu bar icon with a custom circular ghost illustration.
2. Fix a timing bug where `NSSound.play()` is asynchronous — recording begins before the beep finishes, so the beep can be captured by the microphone.
3. Add a "Launch Wisp on Startup" toggle to the menu, backed by `SMAppService`.

## Technical Context

**Language/Version**: Swift 6.1+ with strict concurrency checking enabled
**Primary Dependencies**: AppKit (NSSound, NSStatusItem, NSMenu), ServiceManagement (SMAppService), AVFoundation (existing)
**Storage**: UserDefaults (startup preference, keyed on existing PreferencesStore)
**Testing**: XCTest
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: macOS menu bar desktop app (LSUIElement)
**Performance Goals**: Beep-to-recording delay ≤ beep duration (no added latency beyond the beep itself)
**Constraints**: App is sandboxed/notarized — SMAppService is the correct modern API for login items in this context; legacy SMLoginItemEnabled is not appropriate
**Scale/Scope**: Single-user background utility

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment | Notes |
|-----------|-----------|-------|
| I. Privacy-First Local Processing | ✅ PASS | No network calls introduced. Icon is a local asset. SMAppService is a local system call. |
| II. Type Safety & Correctness | ✅ PASS | NSSound delegate callback is typed. SMAppService returns typed errors. No force-unwraps needed. |
| III. Test-First Development | ✅ PASS | Beep-timing fix and startup-pref toggle are unit-testable with mocks. Icon is visual-only (manual verification). |
| IV. Performance-Conscious Design | ✅ PASS | Adding a delegate callback to NSSound does not affect the audio capture hot path. |
| V. Simplicity & YAGNI | ✅ PASS | Three targeted fixes, no new abstractions. Startup pref reuses PreferencesStore pattern. |

**Post-design re-check**: All principles still satisfied after Phase 1 design (no surprises; changes are additive and contained).

## Project Structure

### Documentation (this feature)

```text
specs/006-polish-and-cleanup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
Wisp/
├── App/
│   └── AppDelegate.swift          # MODIFY: menu setup (startup toggle), recording start sequence
├── Models/
│   └── PreferencesStore.swift     # MODIFY: add launchOnStartup Bool property
├── UI/
│   ├── MenuBarController.swift    # MODIFY: icon asset swap + NSSound delegate for beep timing
│   └── PreferencesView.swift      # MODIFY: add Launch on Startup toggle
├── Resources/
│   ├── Assets.xcassets/           # ADD: ghost icon image set (AppIcon equivalent for status bar)
│   └── Sounds/                    # unchanged
└── Wisp.entitlements              # likely unchanged (SMAppService works in sandbox)
```

**Structure Decision**: Single-project option. All changes are additive modifications to existing files plus one new image asset.

## Complexity Tracking

> No constitution violations — table omitted.

---

## Phase 0: Research

*All findings consolidated in [research.md](research.md)*

**Research tasks executed**:
1. NSSound delegate API for play-completion callback
2. SMAppService API for login items (macOS 13+)
3. SF Symbol / NSImage template rendering for menu bar icons
4. Beep-recording timing root cause analysis

---

## Phase 1: Design

### Beep Timing Fix

**Root cause**: `AppDelegate.swift` lines ~306-311 call `menuBarController?.playStartSound()` and then immediately `audioCaptureService?.startRecording(...)`. `NSSound.play()` is fire-and-forget; there is no await or callback, so recording begins while the beep is still playing.

**Fix design**:
- Adopt `NSSoundDelegate` on `MenuBarController` (or a small dedicated helper).
- Implement `sound(_:didFinishPlaying:)`.
- In `AppDelegate`, instead of calling `startRecording` directly after `playStartSound`, pass a completion closure into `playStartSound(completion:)`.
- `MenuBarController` holds the closure and fires it from the delegate callback.
- This adds zero extra delay — recording starts the instant the beep ends.

**Fallback**: If `NSSoundDelegate` never fires (e.g. sound file missing), start recording after a conservative 600 ms timeout so the feature degrades gracefully.

### Ghost Icon

**Design**:
- A new `StatusBarIcon.pdf` (vector, template-mode) is added to `Assets.xcassets`.
- The asset uses "Template Image" rendering so macOS automatically inverts it for dark/light mode and active/highlight states.
- The ghost shape: a filled circle with a small scalloped bottom edge and two small dot eyes — clearly a ghost, clearly not Nintendo's Wisp (different colour, shape language, no ears, minimal expression).
- `MenuBarController` loads the asset via `NSImage(named:)` and sets `isTemplate = true`.
- The existing state-based icon switching (waveform, mic.fill, etc.) remains — only the idle-state icon changes to the ghost; alternatively all states use a tinted variant of the ghost. Decision: use ghost only for idle, keep existing SF Symbol states for recording/processing so users retain clear feedback.

### Launch on Startup

**Design**:
- Add `launchOnStartup: Bool` to `PreferencesStore`, backed by `UserDefaults`.
- On `didSet`, call `SMAppService.mainApp.register()` or `.unregister()`.
- Add a `Toggle("Launch Wisp on Startup", isOn: $preferences.launchOnStartup)` to `PreferencesView.swift`.
- Additionally add a menu item to the dropdown (`AppDelegate.setupMenuBar`) so it is accessible without opening preferences:
  - Item title: "Launch on Startup" with a checkmark when enabled.
  - `NSMenuItem.state` set to `.on`/`.off` based on current preference.
  - Toggling via the menu calls the same PreferencesStore setter.
- On app launch, sync toggle state with `SMAppService.mainApp.status == .enabled` to handle cases where the user removed the login item from System Settings manually.

**Error handling**: `SMAppService` throws on register/unregister failure. Catch and log; surface an `NSAlert` if the operation fails so users understand the preference was not saved.

### Contracts

This is a menu bar utility with no external API surface. No contracts/ directory needed.

### Agent Context Update

See below — agent context file updated after writing plan.
