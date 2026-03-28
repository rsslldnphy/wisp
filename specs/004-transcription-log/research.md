# Research: Transcription Log

**Feature**: 004-transcription-log
**Date**: 2026-03-28

## Decision 1: Persistence storage format

**Decision**: JSON file in `~/Library/Application Support/Wisp/transcription-log.json`

**Rationale**: The log is a growing list of up to 500 entries. A flat JSON file keeps
the implementation simple (Codable), survives app restarts, and is trivially inspectable.
UserDefaults can technically store arrays but is designed for small scalar preferences, not
bounded-but-growing history lists. CoreData and SQLite add significant complexity with no
benefit at this scale.

**Alternatives considered**:
- UserDefaults — rejected: designed for preferences, not history; awkward to cap at 500 and truncate old entries; harder to test in isolation
- CoreData — rejected: excessive complexity for a flat list of ~500 text records; violates YAGNI (Constitution §V)
- SQLite — rejected: same reason as CoreData; no relational structure needed

## Decision 2: Log window type

**Decision**: `NSWindow` (not NSPanel) containing a SwiftUI `List` view

**Rationale**: The log window should behave like a standard document window — it gets a
Dock Exposé entry, responds to Cmd+W, and is dismissible with normal window controls.
NSPanel is appropriate for ephemeral overlay HUDs (already used for the status indicator).
SwiftUI is explicitly permitted for settings/preferences panels (Constitution §Platform) and
a log view has the same characteristics: no live audio path, no concurrency constraints.

**Alternatives considered**:
- NSPanel — rejected: NSPanel is for floating utility overlays (the status indicator uses this); the log window is a persistent browsable history, not a transient overlay
- Pure AppKit NSTableView — rejected: SwiftUI List achieves the same result with far less boilerplate; constitution permits SwiftUI for panels

## Decision 3: Log entry hook integration point

**Decision**: Add a `TranscriptionLogStore.append(_:)` call in `AppDelegate.handleResult`
immediately after the paste/copy succeeds, capturing the final cleaned text and current timestamp.

**Rationale**: `handleResult` is already the authoritative completion point for all
transcription outcomes. Inserting log persistence there requires a single call site and
does not touch the audio pipeline hot path. The log store write is a simple file append
(rewrite capped JSON), adding negligible latency on the main thread after paste is already complete.

**Alternatives considered**:
- Hook into `transcribeAndPaste` — rejected: that function handles async transcription work; mixing file I/O there increases cognitive complexity
- Hook into `PasteService` — rejected: PasteService should remain focused on clipboard/keypress; logging is app-level concern
- Observe AppState changes — rejected: AppState transitions don't carry the transcribed text payload

## Decision 4: Corrupt data recovery

**Decision**: On JSON decode failure, `TranscriptionLogStore` silently initialises with an
empty array and immediately overwrites the corrupt file (or leaves it absent). No error is
surfaced to the user.

**Rationale**: Clarified in `/speckit.clarify` session (FR-009). A corrupt log file is a
rare scenario; starting fresh is the least disruptive outcome for a background utility app.

## Decision 5: Live update behaviour

**Decision**: The log window loads entries once at open time; it does not observe new
dictations in real-time. Closing and reopening the window shows the latest state.

**Rationale**: Accepted in spec assumptions. Real-time observation requires adding a
Combine/async publisher to `TranscriptionLogStore`, introducing concurrency complexity with
no proportional user benefit — the window is rarely open during active dictation sessions.
This is deferred to a future iteration.
