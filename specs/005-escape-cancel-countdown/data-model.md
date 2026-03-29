# Data Model: Escape Cancel Countdown

## Modified Entities

### AppState

**File**: `Wisp/Models/AppState.swift`

New case added:

| Case | Meaning |
|------|---------|
| `loading` | (existing) Whisper model loading |
| `idle` | (existing) Waiting for hotkey |
| `recording` | (existing) Capturing audio |
| `cancelling` | **NEW** — First Escape pressed; 3-second countdown running before transcription-without-paste is committed |
| `processing` | (existing) Transcription in progress |

New valid transitions added to `transition(to:)`:

| From | To | Trigger |
|------|----|---------|
| `recording` | `cancelling` | First Escape pressed |
| `cancelling` | `processing` | Countdown expires (no paste) OR second Escape pressed (with paste) |
| `cancelling` | `idle` | Audio too short; discard without transcribing |

---

### IndicatorState

**File**: `Wisp/Models/IndicatorState.swift`

New case added:

| Case | Visual |
|------|--------|
| `modelLoading` | (existing) Spinner + "Loading model..." |
| `recording` | (existing) Pulsing red dot + "Recording..." |
| `cancelling` | **NEW** — Orange progress bar draining over 3 s + "Cancelling..." label |
| `transcribing` | (existing) Spinner + "Transcribing..." |
| `error(String)` | (existing) Orange text, auto-dismiss |
| `hidden` | (existing) Invisible |

`from(_: AppState)` mapping update:

```
.cancelling → IndicatorState.cancelling
```

---

### TranscriptionLogEntry

**File**: `Wisp/Models/TranscriptionLogEntry.swift`

New field added:

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `id` | `UUID` | auto | (existing) |
| `text` | `String` | — | (existing) Transcribed + cleaned text |
| `timestamp` | `Date` | `Date()` | (existing) |
| `wasPasted` | `Bool` | `true` | **NEW** — `false` when recording was cancelled via the countdown |

Backward compatibility: `init(from decoder:)` reads `wasPasted` with `decodeIfPresent(_:forKey:) ?? true`, so existing JSON log files without this key continue to decode correctly (treated as pasted entries).

---

## New Runtime State (AppDelegate properties)

These are not persisted; they exist only during the active cancelling phase.

| Property | Type | Lifetime |
|----------|------|----------|
| `pendingAudioBuffer` | `Data?` | Set when first Escape is pressed; cleared after transcription task receives it |
| `shouldPasteAfterProcessing` | `Bool` | Set to `false` when countdown starts; set to `true` if second Escape is pressed; read when `processing` begins |
| `cancelCountdownTask` | `Task<Void, Never>?` | Created when countdown starts; cancelled and set to `nil` if second Escape is pressed or state leaves cancelling |

---

## State Transitions — Full Machine (updated)

```
loading ──► idle ──► recording ──► cancelling ──► processing ──► idle
                         │                 │
                         └────────────────►┘
                         (normal hotkey release)
```

- `recording → cancelling`: first Escape
- `cancelling → processing`: countdown expires (shouldPaste = false) or second Escape (shouldPaste = true)
- `cancelling → idle`: audio too short, no transcription needed
- `recording → processing`: normal hotkey release (existing path, unaffected)
