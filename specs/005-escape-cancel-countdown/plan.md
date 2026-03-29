# Implementation Plan: Escape Cancel Countdown with Progress Bar

**Branch**: `005-escape-cancel-countdown` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-escape-cancel-countdown/spec.md`

## Summary

When Escape is pressed during recording, instead of immediately entering the "Transcribing" state the app enters a new `cancelling` state that shows a 3-second draining orange progress bar labelled "Cancelling...". A second Escape during the countdown reverses the decision — the UI switches to "Transcribing..." and the result is pasted normally. If the countdown expires, the HUD disappears, transcription continues silently in the background, and the result is saved to the log with a `wasPasted = false` flag.

## Technical Context

**Language/Version**: Swift 6.1+ with strict concurrency checking enabled
**Primary Dependencies**: AppKit (NSPanel, Core Animation), WhisperKit (existing), AVFoundation (existing)
**Storage**: JSON file at `~/Library/Application Support/Wisp/transcription-log.json` (existing)
**Testing**: XCTest
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: Desktop app (background utility, LSUIElement)
**Performance Goals**: HUD state transition < 100 ms; countdown animation 3 s ± 100 ms
**Constraints**: All processing on-device; < 50 MB resident memory idle; strict concurrency
**Scale/Scope**: Single user, single active dictation session at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Privacy-First Local Processing | ✅ Pass | No new network calls; audio buffer retained in memory only |
| II. Type Safety & Correctness | ✅ Pass | New `AppState.cancelling` case makes runtime state explicit; `Task` cancellation via cooperative cancellation; `wasPasted` is a typed `Bool` with explicit default |
| III. Test-First Development | ✅ Pass | Tests to be written before implementation per plan tasks |
| IV. Performance-Conscious Design | ✅ Pass | Progress bar animation delegated to Core Animation (render-server side); audio buffer stored as `Data` (existing type) |
| V. Simplicity & YAGNI | ✅ Pass | Minimal additions: 1 new state, 1 new indicator case, 1 Boolean property on log entry, 2 new methods on AppDelegate; countdown duration not user-configurable |

*Post-design re-check*: Constitution check passes. The design avoids speculative abstraction: no new services, no new protocols, no plugin hooks.

## Project Structure

### Documentation (this feature)

```text
specs/005-escape-cancel-countdown/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (affected files)

```text
Wisp/
├── Models/
│   ├── AppState.swift                  # Add .cancelling case + transitions
│   ├── IndicatorState.swift            # Add .cancelling case + from() mapping
│   ├── TranscriptionLogEntry.swift     # Add wasPasted: Bool field
│   └── TranscriptionLogStore.swift     # Add wasPasted param to append()
├── App/
│   └── AppDelegate.swift               # Escape branching, countdown task, buffer retention
└── UI/
    ├── StatusIndicatorView.swift        # New fill-bar subview + .cancelling animation
    └── LogView.swift                    # "not pasted" annotation on entries

WispTests/
├── AppStateTests.swift                 # New cancelling transition tests
├── CancelCountdownTests.swift          # New — countdown task, second Escape
└── TranscriptionLogEntryTests.swift    # wasPasted codability tests
```

**Structure Decision**: Single-project layout, extending existing files only. No new files in `Wisp/` except a new test file (`CancelCountdownTests.swift`).

---

## Phase 0: Research

*See [research.md](research.md) for full rationale. Summary of key decisions:*

1. **Progress bar animation**: `CABasicAnimation` owned by `StatusIndicatorView` — no per-frame timer needed. View starts/stops animation in response to `IndicatorState` changes.
2. **AppState extension**: Add `case cancelling` — keeps state machine as single source of truth. Paste intent tracked as `shouldPasteAfterProcessing: Bool` on `AppDelegate` (simpler than associated values on `.processing`).
3. **Audio buffer retention**: Stop microphone immediately on first Escape; hold `Data` in `pendingAudioBuffer` on `AppDelegate` until the transcription task consumes it.
4. **Log entry flag**: Add `wasPasted: Bool` to `TranscriptionLogEntry` with backward-compatible JSON decoding (absent key → `true`).
5. **Countdown task ownership**: `AppDelegate` owns `cancelCountdownTask: Task<Void, Never>?`; cancelled cooperatively via `.cancel()` on second Escape.

---

## Phase 1: Design & Contracts

*See [data-model.md](data-model.md) for entity details. See [quickstart.md](quickstart.md) for flow overview.*

### AppState changes

```swift
// New case
case cancelling

// New transitions in transition(to:)
case (.recording, .cancelling):    return .success(.cancelling)
case (.cancelling, .processing):   return .success(.processing)
case (.cancelling, .idle):         return .success(.idle)
```

### IndicatorState changes

```swift
case cancelling   // new

// from(_:) addition
case .cancelling: return .cancelling
```

### StatusIndicatorView changes

New subview: `cancelProgressBar: NSView` — layer-backed, orange fill, width equal to view width minus padding, height ~3 pt, positioned below the label.

`update(_:)` gains a `.cancelling` branch:

- Shows label "Cancelling..." in orange
- Hides spinner and recording dot
- Makes `cancelProgressBar` visible
- Calls `startCancelProgressAnimation()` which sets up a `CABasicAnimation` on `cancelProgressBar.layer.bounds.size.width` from full width to 0, duration 3.0 s, `fillMode = .forwards`, `isRemovedOnCompletion = false`

All other branches: call `cancelProgressBar.layer?.removeAllAnimations()` and hide it (same pattern as `recordingDot`).

### AppDelegate changes

New properties:

```swift
private var pendingAudioBuffer: Data?
private var shouldPasteAfterProcessing = false
private var cancelCountdownTask: Task<Void, Never>?
```

`handleEscapeKey()` gains a second branch:

```swift
private func handleEscapeKey() {
    if state == .recording { beginCancelCountdown() }
    else if state == .cancelling { restoreFromCancelling() }
}
```

New `beginCancelCountdown()`:

1. Check audio duration — if < 0.5 s, call `handleResult(.discarded(reason: .tooShort))` and return
2. Stop audio capture, store buffer in `pendingAudioBuffer`
3. Transition `recording → cancelling`
4. Play stop sound
5. Show `overlayWindow?.show(state: .cancelling)`
6. Set `shouldPasteAfterProcessing = false`
7. Launch `cancelCountdownTask`

`cancelCountdownTask` body:

```swift
do {
    try await Task.sleep(for: .seconds(3))
} catch {
    return  // cancelled by second Escape
}
await MainActor.run {
    guard state == .cancelling else { return }
    overlayWindow?.hide()
    guard case .success(let s) = state.transition(to: .processing) else { return }
    state = s
    menuBarController?.updateState(state)
    guard let buffer = pendingAudioBuffer else { return }
    pendingAudioBuffer = nil
    Task { await transcribeAndSave(audioBuffer: buffer) }
}
```

New `restoreFromCancelling()`:

1. `cancelCountdownTask?.cancel(); cancelCountdownTask = nil`
2. `shouldPasteAfterProcessing = true`
3. Transition `cancelling → processing`
4. `overlayWindow?.show(state: .transcribing)`
5. Guard `pendingAudioBuffer`, set to nil
6. `Task { await transcribeAndPaste(audioBuffer: buffer) }`

`handleResult(.completed)` passes `wasPasted` flag:

```swift
logStore.append(text: text, wasPasted: shouldPasteAfterProcessing)
// Reset after use:
shouldPasteAfterProcessing = false
```

> Note: `transcribeAndPaste` path sets `shouldPasteAfterProcessing = true` before calling `handleResult`; `transcribeAndSave` path leaves it `false`.

### TranscriptionLogEntry changes

```swift
let wasPasted: Bool

init(id: UUID = UUID(), text: String, timestamp: Date = Date(), wasPasted: Bool = true) { … }

init(from decoder: Decoder) throws {
    // existing fields …
    wasPasted = try container.decodeIfPresent(Bool.self, forKey: .wasPasted) ?? true
}
```

### TranscriptionLogStore changes

```swift
func append(text: String, wasPasted: Bool = true) {
    let entry = TranscriptionLogEntry(text: text, wasPasted: wasPasted)
    // rest unchanged
}
```

### LogView changes

Entries where `!entry.wasPasted` display a small muted "not pasted" label below the text (e.g., `.caption2` font, `.tertiaryLabelColor`).

---

## No External Contracts

This is a background desktop utility with no public API, CLI interface, or network endpoints. The `/contracts/` directory is not required.
