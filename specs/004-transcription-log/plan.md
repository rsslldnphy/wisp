# Implementation Plan: Transcription Log

**Branch**: `004-transcription-log` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-transcription-log/spec.md`

## Summary

Add a "Show Log" menu item to the Wisp menu bar app that opens a window displaying the
last up to 500 transcriptions in reverse-chronological order, with a per-entry copy button.
Transcription history is persisted to a local JSON file in Application Support and survives
app restarts. No network, no sync, no real-time updates.

## Technical Context

**Language/Version**: Swift 6.1+ with strict concurrency checking enabled
**Primary Dependencies**: AppKit (NSWindow, NSMenu), SwiftUI (List, Button), Foundation (Codable, JSONEncoder/Decoder, FileManager)
**Storage**: JSON file — `~/Library/Application Support/Wisp/transcription-log.json`
**Testing**: XCTest (existing test target `WispTests`)
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: macOS menu bar desktop app (LSUIElement)
**Performance Goals**: Log window opens in <1 s; write after each transcription adds <5 ms
**Constraints**: Offline-only; log capped at 500 entries; corrupt data silently discarded
**Scale/Scope**: Single user; ≤500 entries; no concurrency on log store (main actor)

## Constitution Check

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Privacy-First Local Processing | ✅ Pass | Log stored only on-device; no network calls; no telemetry |
| II. Type Safety & Correctness | ✅ Pass | Codable types with explicit fields; no force-unwraps; guard let on file load |
| III. Test-First Development | ✅ Pass | XCTest required for TranscriptionLogStore (append, cap, persist, corrupt recovery) and LogView empty/populated states |
| IV. Performance-Conscious Design | ✅ Pass | File I/O is post-paste on main thread (negligible); log window load is one JSON decode of ≤500 small objects |
| V. Simplicity & YAGNI | ✅ Pass | Minimal new surface: 1 store, 1 window, 1 SwiftUI view, 1 menu item; no delete, no search, no real-time updates in v1 |

**Gate result**: PASS — no violations, no Complexity Tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/004-transcription-log/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code

```text
Wisp/
├── App/
│   └── AppDelegate.swift         # MODIFIED: add menu item; init log store; hook append after handleResult
├── Models/
│   ├── TranscriptionLogEntry.swift   # NEW: Codable struct (id, text, timestamp)
│   └── TranscriptionLogStore.swift   # NEW: @MainActor; load/append/cap/persist
└── UI/
    ├── LogWindow.swift               # NEW: NSWindow wrapper (open/close/bring to front)
    └── LogView.swift                 # NEW: SwiftUI List with copy buttons + empty state

WispTests/
└── TranscriptionLogStoreTests.swift  # NEW: unit tests (append, cap at 500, persist, corrupt recovery)
```

**Structure Decision**: Single project, existing layout. New files slot into the established
`Models/` and `UI/` directories. No new directories needed.

## Implementation Phases

### Phase A: Data Layer

1. Create `TranscriptionLogEntry.swift` — `Codable`, `Identifiable`, `Sendable` struct with `id: UUID`, `text: String`, `timestamp: Date`.
2. Create `TranscriptionLogStore.swift` — `@MainActor final class`:
   - `private(set) var entries: [TranscriptionLogEntry]`
   - `init()` loads from JSON (silently empty on failure)
   - `func append(text: String)` — creates entry with `Date()`, prepends, drops oldest if over 500, saves
   - `private func save()` — encodes entries to JSON, writes to Application Support path
   - `static var storageURL: URL` — computed URL for `transcription-log.json`
3. Write `TranscriptionLogStoreTests.swift` **first** (TDD):
   - `testAppend_addsEntry()`
   - `testAppend_capsAt500_dropsOldest()`
   - `testPersistence_survivesReinit()`
   - `testCorruptFile_startsEmpty()`

### Phase B: UI Layer

1. Create `LogView.swift` — SwiftUI `View`:
   - `List` of entries sorted newest-first; each row shows timestamp (formatted "Mar 28, 2:32 PM") + text + copy `Button`
   - Empty state: `ContentUnavailableView` or `Text("No transcriptions yet")`
   - Copy button calls `NSPasteboard.general.setString(_:forType:)`
2. Create `LogWindow.swift` — thin `NSWindow` subclass or factory:
   - Standard titled, closable, resizable window
   - Hosts `LogView` via `NSHostingView`
   - `func show(store: TranscriptionLogStore)` — opens or brings to front

### Phase C: Integration

1. Modify `AppDelegate.swift`:
   - Add `private var logStore = TranscriptionLogStore()` property
   - Add `private var logWindow: LogWindow?` property
   - In menu setup, insert `NSMenuItem(title: "Show Log", action: #selector(showLog), keyEquivalent: "")` before the existing separator
   - Add `@objc func showLog()` — creates or reuses `logWindow`, calls `logWindow.show(store: logStore)`
   - In `handleResult`, after successful paste/copy, call `logStore.append(text: finalText)`

## Key Design Decisions

See [research.md](research.md) for full rationale on each decision.

| Decision | Choice |
| -------- | ------ |
| Storage format | JSON file in Application Support |
| Window type | NSWindow + SwiftUI content |
| Integration point | `AppDelegate.handleResult` post-paste |
| Corrupt data | Silent discard, empty log |
| Live updates | Static snapshot at window-open time |

## Open Items / Deferred

- Real-time log refresh while window is open (deferred to future iteration; requires Combine observer on store)
- Individual entry deletion or "Clear All" (explicitly out of scope for v1 per spec assumptions)
- Log entry display for very long transcriptions (truncate with expand, deferred to v1.1)
