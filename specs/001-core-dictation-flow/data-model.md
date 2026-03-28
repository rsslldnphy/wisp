# Data Model: Core Dictation Flow

**Date**: 2026-03-28
**Feature**: 001-core-dictation-flow

## Entities

### AppState

Represents the current operational mode of the application.

**Values**: `idle`, `recording`, `processing`

**State Transitions**:

```text
          hotkey press           hotkey press / auto-stop
  idle ──────────────► recording ──────────────────────► processing
   ▲                                                        │
   │              transcription complete / error             │
   └────────────────────────────────────────────────────────┘
```

**Transition Rules**:
- `idle → recording`: Hotkey pressed AND microphone available AND
  not currently processing
- `recording → processing`: Hotkey pressed OR 5-minute max reached
- `processing → idle`: Transcription succeeds (text pasted) OR
  transcription fails (error notification shown)
- All other transitions: ignored (e.g., hotkey during processing)

### DictationSession

Represents a single record-transcribe-paste cycle.

**Attributes**:

| Attribute        | Type              | Description                          |
|------------------|-------------------|--------------------------------------|
| id               | UUID              | Unique session identifier            |
| startTime        | Date              | When recording began                 |
| endTime          | Date?             | When recording stopped (nil if active) |
| audioDuration    | TimeInterval      | Duration of captured audio in seconds |
| result           | TranscriptionResult | Outcome of the session              |

### TranscriptionResult

Represents the outcome of a dictation session.

**Cases**:
- `completed(text: String)` — Transcription succeeded; text is the
  cleaned output ready for pasting
- `discarded(reason: DiscardReason)` — Recording was too short or
  contained no speech
- `failed(error: TranscriptionError)` — Transcription process failed

### DiscardReason

**Values**:
- `tooShort` — Recording shorter than 0.5 seconds
- `noSpeechDetected` — Audio contained no recognizable speech

### TranscriptionError

**Values**:
- `modelNotLoaded` — Whisper model not available
- `processingFailed(underlying: Error)` — Runtime transcription error
- `microphoneUnavailable` — No input device accessible
- `permissionDenied` — Microphone permission revoked

## Relationships

- An `AppState` machine owns zero or one active `DictationSession`
- A `DictationSession` produces exactly one `TranscriptionResult`
- `TranscriptionResult.completed` triggers paste or clipboard write
- `TranscriptionResult.discarded` and `.failed` trigger notification

## Data Volume

- No persistent storage required for this feature
- Audio buffers: max ~9.6 MB in memory (5 min × 16kHz × 4 bytes)
- Session objects are ephemeral — created on record start, discarded
  after result is delivered
