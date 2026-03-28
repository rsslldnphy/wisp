# Tasks: Transcription Log

**Input**: Design documents from `/specs/004-transcription-log/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Paths follow the existing project layout: `Wisp/` for source, `WispTests/` for tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure Application Support directory is handled and existing project is ready for new files.

- [x] T001 Verify `~/Library/Application Support/Wisp/` directory creation is handled in TranscriptionLogStore (no new files yet — document the path in a comment inside the store file once created)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data layer that MUST be complete before either user story can be implemented. Both US1 and US2 depend on `TranscriptionLogEntry` and `TranscriptionLogStore`.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

> **TDD**: Write tests FIRST (T002), ensure they FAIL, then implement (T003, T004).

- [x] T002 Write failing XCTest suite for TranscriptionLogStore in `WispTests/TranscriptionLogStoreTests.swift` covering: `testAppend_addsEntry`, `testAppend_capsAt500_dropsOldest`, `testPersistence_survivesReinit`, `testCorruptFile_startsEmpty`
- [x] T003 [P] Create `TranscriptionLogEntry` Codable+Identifiable+Sendable struct in `Wisp/Models/TranscriptionLogEntry.swift` with fields: `id: UUID`, `text: String`, `timestamp: Date`
- [x] T004 Create `TranscriptionLogStore` @MainActor final class in `Wisp/Models/TranscriptionLogStore.swift` with: `static var storageURL: URL`, `private(set) var entries: [TranscriptionLogEntry]`, `init()` loading from JSON (silent empty on failure), `func append(text: String)` (cap at 500, drop oldest, save), `private func save()` writing JSON to storageURL (depends on T003)

**Checkpoint**: Run `TranscriptionLogStoreTests` — all four tests must pass before proceeding.

---

## Phase 3: User Story 1 — View Transcription History (Priority: P1) 🎯 MVP

**Goal**: User can open "Show Log" from the menu bar and see a list of their recent transcriptions in reverse-chronological order, with timestamps.

**Independent Test**: Perform a dictation, open Show Log from menu, verify the transcription appears at the top of the list with a formatted timestamp (e.g., "Mar 28, 2:32 PM"). Verify empty state when no transcriptions exist.

### Implementation for User Story 1

- [x] T005 [P] [US1] Create `LogView` SwiftUI View in `Wisp/UI/LogView.swift` displaying entries as a `List` sorted newest-first; each row shows formatted timestamp ("MMM d, h:mm a") and transcribed text; empty state shows `Text("No transcriptions yet.")` when entries array is empty (depends on T003)
- [x] T006 [P] [US1] Create `LogWindow` NSWindow factory/class in `Wisp/UI/LogWindow.swift` that hosts `LogView` via `NSHostingView`, standard titled/closable/resizable window, `func show(entries: [TranscriptionLogEntry])` opens window or brings it to front (depends on T005)
- [x] T007 [US1] Modify `Wisp/App/AppDelegate.swift`: add `private var logStore = TranscriptionLogStore()` property; add `private var logWindow: LogWindow?` property; in menu setup add `NSMenuItem(title: "Show Log", action: #selector(showLog), keyEquivalent: "")` before the existing separator; add `@objc func showLog()` that creates/reuses logWindow and calls `logWindow.show(entries: logStore.entries)` (depends on T004, T006)
- [x] T008 [US1] Modify `Wisp/App/AppDelegate.swift`: in `handleResult`, after successful paste or clipboard-copy, call `logStore.append(text: finalText)` to record the completed transcription (depends on T007)

**Checkpoint**: Build and run. Dictate something, open Show Log — entry should appear with timestamp. Open with no history — empty state message should show.

---

## Phase 4: User Story 2 — Copy a Transcription from Log (Priority: P2)

**Goal**: Each log entry has a copy button that places the entry's text on the system clipboard when clicked.

**Independent Test**: Open Show Log, click the copy button on any entry, paste into a text field — the exact transcribed text should appear.

### Implementation for User Story 2

- [x] T009 [US2] Modify `Wisp/UI/LogView.swift`: add a copy `Button` to each list row that calls `NSPasteboard.general.clearContents()` then `NSPasteboard.general.setString(entry.text, forType: .string)`; button label should be a clipboard SF Symbol (e.g., `"doc.on.doc"`) (depends on T005)

**Checkpoint**: Build and run. Open Show Log, click copy on an entry, paste elsewhere — exact text appears. Copying a second entry replaces the first on the clipboard.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final quality pass across both stories.

- [x] T010 [P] Review `TranscriptionLogStore.swift` for Swift 6 strict concurrency warnings — ensure all file I/O is safe and `@MainActor` isolation is correct in `Wisp/Models/TranscriptionLogStore.swift`
- [x] T011 [P] Review `LogView.swift` timestamp formatting — confirm `DateFormatter` or `FormatStyle` produces correct output (e.g., "Mar 28, 2:32 PM") for same-day and cross-day entries in `Wisp/UI/LogView.swift`
- [x] T012 Run full test suite (`swift test`) and verify all `TranscriptionLogStoreTests` pass in `WispTests/TranscriptionLogStoreTests.swift`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories; T002 must be written first (TDD)
- **User Story 1 (Phase 3)**: Depends on Foundational completion (T003, T004)
- **User Story 2 (Phase 4)**: Depends on US1 LogView existing (T005) — adds to it
- **Polish (Phase 5)**: Depends on both stories complete

### User Story Dependencies

- **US1 (P1)**: Starts after T003 + T004 complete. T005 and T006 can run in parallel. T007 depends on both T004 and T006. T008 depends on T007.
- **US2 (P2)**: Starts after T005 (LogView exists). Single task T009.

### Within Each Phase

- T002 (tests) written FIRST and must FAIL before T003/T004 implementation
- T003 and T004 are sequential (store depends on entry struct)
- T005 and T006 can run in parallel once T003 is done
- T007 integrates T004 + T006 — sequential
- T008 extends T007 — sequential
- T009 modifies T005 — sequential

---

## Parallel Execution Examples

### Phase 2 (after T002 written and failing)

```text
T003: Create TranscriptionLogEntry.swift   ← start immediately
# T004 waits for T003
```

### Phase 3 (after T004 complete)

```text
T005: Create LogView.swift        ← start in parallel
T006: Create LogWindow.swift      ← start in parallel (waits for T005 via NSHostingView)
# T007 waits for T004 + T006
# T008 waits for T007
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (write failing tests → implement store)
2. Complete Phase 3: User Story 1 (view log from menu)
3. **STOP and VALIDATE**: Dictate, open log, verify entry with timestamp appears
4. Ship MVP — log is useful even without copy button

### Incremental Delivery

1. Complete Setup + Foundational → data layer ready
2. Add User Story 1 → browsable history in menu → **Demo/Ship**
3. Add User Story 2 → copy button per entry → **Demo/Ship**
4. Apply Polish

---

## Notes

- [P] tasks = different files, no blocking dependencies between them
- [US1] / [US2] labels map tasks to spec user stories for traceability
- Constitution §III requires TDD: T002 tests must be written and FAILING before T003/T004 implementation
- Constitution §II: no force-unwraps in store file I/O — use `guard let` / `try?`
- `TranscriptionLogStore` is `@MainActor` — consistent with existing AppDelegate patterns
- `LogWindow` should be dismissed with Cmd+W (standard NSWindow behaviour, no special handling needed)
