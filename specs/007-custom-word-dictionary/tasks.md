# Tasks: Custom Word Dictionary for Transcription Accuracy

**Input**: Design documents from `/specs/007-custom-word-dictionary/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Included — the Wisp Constitution (Principle III) mandates test-first development with XCTest covering the happy path and primary failure mode for every user-facing behaviour.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new file scaffolds in the existing Xcode project so later tasks can fill them without merge conflicts.

- [x] T001 Create empty `Wisp/Models/WordDictionaryStore.swift` with `import Foundation` placeholder
- [x] T002 Create empty `Wisp/UI/WordDictionaryView.swift` with `import SwiftUI` placeholder
- [x] T003 [P] Create empty `WispTests/WordDictionaryStoreTests.swift` with `import XCTest` placeholder
- [x] T004 [P] Create empty `WispTests/WordExtractionTests.swift` with `import XCTest` placeholder
- [x] T005 [P] Create empty `WispTests/LogEntryEditTests.swift` with `import XCTest` placeholder

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core changes that all three user stories depend on. Must complete before any story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T006 Promote `text` field from `let` to `var` in `Wisp/Models/TranscriptionLogEntry.swift`
- [x] T007 Add `update(id: UUID, text: String)` method to `TranscriptionLogStore` that replaces the matching entry in-place and calls `save()` in `Wisp/Models/TranscriptionLogStore.swift`
- [x] T008 Implement `WordDictionaryStore` — `@MainActor @Observable final class` with `words: [String]`, `init(defaults: UserDefaults = .standard)` loading from `com.wisp.wordDictionary`, `add(_ word: String)` (trim + case-insensitive dedup + persist), `update(at index: Int, word: String)` (replace + persist), `remove(at offsets: IndexSet)` (persist), `remove(_ word: String)`, `contains(_ word: String) -> Bool`, and private `persist()` writing back to UserDefaults in `Wisp/Models/WordDictionaryStore.swift`
- [x] T009 Add `static func extractNewWords(from oldText: String, to newText: String) -> [String]` to `WordDictionaryStore` — splits both strings on whitespace/newlines, strips leading/trailing punctuation from each token, returns tokens present in `newText` but absent (case-insensitive) from `oldText`, deduplicated, ignoring blank tokens in `Wisp/Models/WordDictionaryStore.swift`
- [x] T010 Instantiate `WordDictionaryStore` as a stored property on `AppDelegate` (alongside `PreferencesStore`) in `Wisp/App/AppDelegate.swift`

**Checkpoint**: Foundation ready — `WordDictionaryStore` exists and is wired into `AppDelegate`. User story phases can now proceed.

---

## Phase 3: User Story 1 — Automatic Dictionary Learning from Edits (Priority: P1) 🎯 MVP

**Goal**: Editing a word in a transcription result automatically adds the corrected word to the dictionary, and that dictionary is injected into every future transcription.

**Independent Test**: Dictate a phrase, edit a word in the log, open Preferences → Transcription Dictionary and confirm the word appears. Dictate the same phrase again and confirm the corrected spelling is used.

### Tests for User Story 1

> **Write these tests FIRST — confirm they FAIL before implementing**

- [x] T011 [US1] Write `WordDictionaryStoreTests`: happy-path `add` appends word; duplicate (case-insensitive) is ignored; blank/whitespace input is ignored; `remove` deletes by word; `contains` returns correct bool in `WispTests/WordDictionaryStoreTests.swift`
- [x] T012 [P] [US1] Write `WordExtractionTests`: new word detected; unchanged word not returned; punctuation-wrapped word stripped correctly; blank result token ignored; all-same input returns empty array in `WispTests/WordExtractionTests.swift`
- [x] T013 [P] [US1] Write `LogEntryEditTests`: committing a word edit calls `extractNewWords` and adds result to `WordDictionaryStore`; committing with no changed words adds nothing; blank edit does not add to dictionary in `WispTests/LogEntryEditTests.swift`

### Implementation for User Story 1

- [x] T014 [US1] Add `@State private var isEditing: Bool = false` and `@State private var editDraft: String = ""` to `LogEntryRow`; replace the read-only `Text(entry.text)` with a conditional: show `TextEditor(text: $editDraft)` when `isEditing`, `Text(entry.text).onTapGesture { ... }` otherwise in `Wisp/UI/LogView.swift`
- [x] T015 [US1] Implement edit commit handler in `LogEntryRow`: on Return key / focus loss, call `WordDictionaryStore.extractNewWords(from: entry.text, to: editDraft)`, call `wordDictionary.add(_:)` for each result, call `logStore.update(id: entry.id, text: editDraft)`, then set `isEditing = false` — pass `wordDictionary: WordDictionaryStore` and `logStore: TranscriptionLogStore` as parameters to `LogEntryRow` in `Wisp/UI/LogView.swift`
- [x] T016 [US1] Pass `wordDictionary` and `logStore` from `LogView` down to each `LogEntryRow` initialiser in `Wisp/UI/LogView.swift`
- [x] T017 [US1] Modify `TranscriptionService.transcribe(audioBuffer: Data)` to accept `wordHints: [String] = []`; construct `DecodingOptions(initialPrompt: "Common words and spellings: \(wordHints.joined(separator: ", "))")` when `wordHints` is non-empty and pass to the WhisperKit transcribe call in `Wisp/Services/TranscriptionService.swift`
- [x] T018 [US1] Modify `TextCleanupService.cleanup(_ text: String)` to accept `wordHints: [String] = []`; when non-empty, append `"\nUse these exact spellings when they appear: \(wordHints.joined(separator: ", "))"` to the prompt before calling `session.respond(to:)` in `Wisp/Services/TextCleanupService.swift`
- [x] T019 [US1] Update `AppDelegate.transcribeAndPaste(audioBuffer:)` to pass `wordDictionary.words` to both `transcriptionService?.transcribe(audioBuffer:wordHints:)` and `textCleanupService?.cleanup(_:wordHints:)` in `Wisp/App/AppDelegate.swift`

**Checkpoint**: User Story 1 fully functional. Edit a log entry → word appears in dictionary → next transcription uses it.

---

## Phase 4: User Story 2 — View and Manage Dictionary in Settings (Priority: P2)

**Goal**: Users can view, add, edit, and delete dictionary words from the Preferences panel without performing a dictation.

**Independent Test**: Open Preferences, navigate to Transcription Dictionary, add a word, edit it, delete it — verify the list updates correctly at each step. Works without ever making a transcription.

### Tests for User Story 2

> **Write these tests FIRST — confirm they FAIL before implementing**

- [x] T020 [US2] Write test for `WordDictionaryView` add-word flow: tapping "Add Word", entering text, confirming — verifies new word appears in `WordDictionaryStore.words` in `WispTests/WordDictionaryStoreTests.swift`
- [x] T021 [P] [US2] Write test for `WordDictionaryView` delete-word flow: deleting an entry via swipe/button — verifies word is removed from `WordDictionaryStore.words` in `WispTests/WordDictionaryStoreTests.swift`

### Implementation for User Story 2

- [x] T022 [US2] Implement `WordDictionaryView` — SwiftUI `List` iterating `wordDictionary.words` with per-row swipe-to-delete, inline edit on tap (double-tap or edit button), an "Add Word" toolbar button that appends a new inline text field, and an empty-state `ContentUnavailableView` (or `Text`) when the list is empty; accepts `@Bindable var wordDictionary: WordDictionaryStore` in `Wisp/UI/WordDictionaryView.swift`
- [x] T023 [US2] Add a `Section("Transcription Dictionary") { WordDictionaryView(wordDictionary: wordDictionary) }` to the grouped `Form` in `PreferencesView`, placed after the Cleanup Prompt section in `Wisp/UI/PreferencesView.swift`
- [x] T024 [US2] Add `wordDictionary: WordDictionaryStore` parameter to `PreferencesView.init` and to `PreferencesWindow.show(preferences:microphoneList:wordDictionary:)` in `Wisp/UI/PreferencesView.swift` and `Wisp/UI/PreferencesWindow.swift`
- [x] T025 [US2] Update `AppDelegate.openPreferences()` to pass `wordDictionary` to `PreferencesWindow.show(preferences:microphoneList:wordDictionary:)` in `Wisp/App/AppDelegate.swift`

**Checkpoint**: User Stories 1 and 2 both independently functional. Dictionary visible and editable in settings.

---

## Phase 5: User Story 3 — Dictionary Persists Across App Restarts (Priority: P3)

**Goal**: Dictionary words survive app quit and relaunch.

**Independent Test**: Add a word, quit the app, relaunch, open Preferences → Transcription Dictionary — word still present.

### Tests for User Story 3

> **Write these tests FIRST — confirm they FAIL before implementing**

- [x] T026 [US3] Write UserDefaults round-trip test: create `WordDictionaryStore(defaults: inMemoryDefaults)`, add words, create a second `WordDictionaryStore(defaults: inMemoryDefaults)`, verify `words` matches in `WispTests/WordDictionaryStoreTests.swift`
- [x] T027 [P] [US3] Write test that a deleted word does not reappear after a fresh `WordDictionaryStore` init from the same UserDefaults in `WispTests/WordDictionaryStoreTests.swift`

### Implementation for User Story 3

- [x] T028 [US3] Verify `WordDictionaryStore.init(defaults:)` correctly decodes `[String]` from `com.wisp.wordDictionary`; confirm `persist()` writes the full array atomically; add nil-guard so missing key produces empty `words` (not a crash) in `Wisp/Models/WordDictionaryStore.swift`
- [x] T029 [US3] Audit `WordDictionaryStore` for Swift 6.1 strict concurrency: confirm `@MainActor` isolation is correct, `words` mutations only occur on main actor, and `UserDefaults` calls are safe from the main actor in `Wisp/Models/WordDictionaryStore.swift`

**Checkpoint**: All three user stories independently functional and persisted.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Input validation, empty-state UX, and final verification.

- [x] T030 [P] Add guard in `WordDictionaryView` add-word flow that disables the confirm button and shows an inline hint when the input is blank or whitespace-only in `Wisp/UI/WordDictionaryView.swift`
- [x] T031 [P] Add guard in `LogEntryRow` edit commit handler that rejects blank/whitespace-only edits (restores original text, does not add to dictionary) in `Wisp/UI/LogView.swift`
- [x] T032 [P] Add guard in `WordDictionaryStore.add(_:)` that strips whitespace and returns early if the result is empty, ensuring no blank entries can be persisted regardless of call site in `Wisp/Models/WordDictionaryStore.swift`
- [x] T033 Review all modified files against the Wisp Constitution: no force-unwraps, explicit `@MainActor` where needed, no speculative features added beyond spec scope
- [ ] T034 Run quickstart.md validation end-to-end: build, dictate phrase with unusual word, correct in log, verify dictionary in settings, dictate again, confirm improvement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2
- **User Story 2 (Phase 4)**: Depends on Phase 2 (and benefits from US1's `WordDictionaryStore`, but is independently testable)
- **User Story 3 (Phase 5)**: Depends on Phase 2 (`WordDictionaryStore` persistence is already implemented there; this phase adds tests + audit)
- **Polish (Phase 6)**: Depends on all user story phases being complete

### User Story Dependencies

- **US1 (P1)**: Can start immediately after Phase 2 — no dependency on US2 or US3
- **US2 (P2)**: Can start immediately after Phase 2 — no dependency on US1 (manages same `WordDictionaryStore` but through a different UI surface)
- **US3 (P3)**: Can start immediately after Phase 2 — persistence is in `WordDictionaryStore`; this phase is primarily tests + concurrency audit

### Within Each User Story

- Tests written and confirmed FAILING before implementation (Constitution Principle III)
- Model/store tasks before service tasks before UI tasks
- Core implementation before integration wiring

### Parallel Opportunities

- T003, T004, T005 (Phase 1): all independent new files
- T012, T013 (US1 tests): different files
- T017, T018 (US1 implementation): different service files
- T020, T021 (US2 tests): same file but separate test methods — write sequentially
- T026, T027 (US3 tests): same file, write sequentially
- T030, T031, T032 (Polish): different files

---

## Parallel Example: User Story 1

```
# After T011 (WordDictionaryStoreTests), launch in parallel:
T012 — WordExtractionTests.swift
T013 — LogEntryEditTests.swift

# After foundational T017/T018 dependencies are clear:
T017 — TranscriptionService.swift (wordHints param)
T018 — TextCleanupService.swift (prompt augmentation)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T005)
2. Complete Phase 2: Foundational (T006–T010)
3. Complete Phase 3: User Story 1 (T011–T019)
4. **STOP and VALIDATE**: Edit a transcription word → appears in dictionary → next transcription uses it
5. This delivers the core automatic learning loop

### Incremental Delivery

1. Setup + Foundational → `WordDictionaryStore` exists
2. User Story 1 → Edit-to-learn loop works
3. User Story 2 → Settings management panel ready
4. User Story 3 → Persistence confirmed and tested
5. Polish → Input validation and final audit

---

## Notes

- [P] tasks operate on different files with no cross-dependencies
- [Story] label maps each task to the user story it delivers
- Each user story phase is independently completable and testable
- Tests must fail before implementation (red-green-refactor per Constitution)
- `inMemoryDefaults` in US3 tests: use `UserDefaults(suiteName: UUID().uuidString)!` for test isolation
- `WordDictionaryStore.add` is the single validated entry point — all call sites go through it
