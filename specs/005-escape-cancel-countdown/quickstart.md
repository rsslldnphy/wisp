# Quickstart: Escape Cancel Countdown

A concise guide to the new flow and touch-points for anyone picking up this feature.

## What Changed vs. the Previous Escape Behaviour

| Step | Before (commit `3eaa047`) | After (this feature) |
|------|--------------------------|----------------------|
| User presses Escape while recording | Recording stops; immediately shows "Transcribing..." | Recording stops; shows "Cancelling..." with a draining orange progress bar |
| 3 seconds pass with no further input | N/A | HUD disappears; transcription runs silently; result saved to log with `wasPasted = false` |
| User presses Escape a second time during countdown | N/A | Countdown cancelled; HUD switches to "Transcribing..."; result pasted normally with `wasPasted = true` |

## Files to Touch

| File | Change |
|------|--------|
| `Wisp/Models/AppState.swift` | Add `case cancelling`; add transitions `recording→cancelling`, `cancelling→processing`, `cancelling→idle` |
| `Wisp/Models/IndicatorState.swift` | Add `case cancelling`; update `from(_:)` |
| `Wisp/Models/TranscriptionLogEntry.swift` | Add `wasPasted: Bool` with `true` default; implement backward-compatible `Decodable` |
| `Wisp/Models/TranscriptionLogStore.swift` | Add `wasPasted` parameter to `append(text:wasPasted:)` |
| `Wisp/UI/StatusIndicatorView.swift` | Add progress bar subview; handle `.cancelling` in `update(_:)` with a 3 s `CABasicAnimation` |
| `Wisp/App/AppDelegate.swift` | Add `pendingAudioBuffer`, `shouldPasteAfterProcessing`, `cancelCountdownTask` properties; refactor `handleEscapeKey()` to branch on `.cancelling` state; add `beginCancelCountdown()` and `restoreFromCancelling()` |
| `Wisp/UI/LogView.swift` | Show "not pasted" annotation on entries where `wasPasted == false` |
| `WispTests/` | Tests for new state transitions, countdown cancellation, log entry flag |

## Key Code Paths

### First Escape (new)

```
handleEscapeKey()
  state == .recording → beginCancelCountdown()
    stop audio capture → store buffer in pendingAudioBuffer
    transition state: recording → cancelling
    overlayWindow.show(state: .cancelling)          ← new indicator state
    cancelCountdownTask = Task {
      try await Task.sleep(for: .seconds(3))
      // countdown expired
      overlayWindow.hide()
      transition state: cancelling → processing
      shouldPasteAfterProcessing = false
      Task { await transcribeAndSave(audioBuffer: pendingAudioBuffer!) }
    }
```

### Second Escape (new)

```
handleEscapeKey()
  state == .cancelling → restoreFromCancelling()
    cancelCountdownTask?.cancel()
    cancelCountdownTask = nil
    shouldPasteAfterProcessing = true
    transition state: cancelling → processing
    overlayWindow.show(state: .transcribing)        ← existing indicator state
    Task { await transcribeAndPaste(audioBuffer: pendingAudioBuffer!) }
```

### Log Save (updated)

```
handleResult(.completed(text:))
  logStore.append(text: cleanedText, wasPasted: shouldPasteAfterProcessing)
```

## Testing Checklist

- [ ] First Escape → HUD shows "Cancelling..." with orange fill bar
- [ ] Fill bar drains over ~3 seconds
- [ ] After 3 seconds → HUD disappears, no paste, log entry appears with `wasPasted = false`
- [ ] First Escape + Second Escape → HUD switches to "Transcribing...", result pasted, log entry `wasPasted = true`
- [ ] Normal hotkey release → completely unaffected (no regression)
- [ ] Audio too short when Escape pressed → discarded, no countdown shown
- [ ] Log view shows visual distinction for not-pasted entries
