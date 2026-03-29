# Tasks: Escape Cancel Countdown with Progress Bar

**Input**: Design documents from `/specs/005-escape-cancel-countdown/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Included per constitution requirement (TDD — write tests first, confirm they fail, then implement).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm baseline compiles and test target is healthy before modifications begin.

- [x] T001 Confirm the project builds cleanly and the `WispTests` target passes all existing tests (run `xcodebuild test -scheme Wisp`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core model changes required by all three user stories. No user story work can begin until this phase is complete.

**⚠️ CRITICAL**: Both tasks touch different files and can run in parallel.

- [x] T002 [P] Add `case cancelling` to `AppState` and add valid transitions `recording→cancelling`, `cancelling→processing`, `cancelling→idle` in `Wisp/Models/AppState.swift`
- [x] T003 [P] Add `case cancelling` to `IndicatorState` and map it in `from(_:)` (`AppState.cancelling → IndicatorState.cancelling`) in `Wisp/Models/IndicatorState.swift`

**Checkpoint**: Foundation ready — project must still compile with no errors after T002 and T003.

---

## Phase 3: User Story 1 — Escape Triggers Cancellation Countdown (Priority: P1) 🎯 MVP

**Goal**: Pressing Escape during recording stops audio capture and shows a "Cancelling..." HUD with a draining 3-second progress bar. After 3 seconds the HUD disappears; no paste occurs.

**Independent Test**: Start recording, press Escape, verify the "Cancelling..." HUD with a progress bar appears and drains for ~3 seconds, then disappears with no paste. Confirmed by running `WispTests/AppStateTests.swift` and `WispTests/CancelCountdownTests.swift`.

### Tests for User Story 1

> **Write these tests first — confirm they FAIL before writing any implementation.**

- [x] T004 [P] [US1] Add test cases for `recording→cancelling`, `cancelling→processing`, and `cancelling→idle` transitions (including invalid transition guard) in `WispTests/AppStateTests.swift`
- [x] T005 [P] [US1] Add test case verifying `IndicatorState.from(.cancelling) == .cancelling` in `WispTests/IndicatorStateTests.swift`
- [x] T006 [P] [US1] Create `WispTests/CancelCountdownTests.swift`; add test: calling `beginCancelCountdown()` when audio duration ≥ 0.5 s transitions `state` to `.cancelling` and sets `pendingAudioBuffer` to a non-nil value
- [x] T007 [P] [US1] In `WispTests/CancelCountdownTests.swift`, add test: calling `beginCancelCountdown()` when audio duration < 0.5 s keeps `state` at `.idle` (discards without countdown)

### Implementation for User Story 1

- [x] T008 [P] [US1] Add `cancelProgressBar: NSView` subview (layer-backed, orange fill, ~3 pt height, width fills HUD minus padding) with Auto Layout constraints positioned below the label in `Wisp/UI/StatusIndicatorView.swift`
- [x] T009 [US1] Add `.cancelling` case to `StatusIndicatorView.update(_:)`: show "Cancelling..." label in orange, hide spinner and recording dot, show `cancelProgressBar`, call `startCancelProgressAnimation()` in `Wisp/UI/StatusIndicatorView.swift` (depends on T008)
- [x] T010 [US1] Implement `startCancelProgressAnimation()` using `CABasicAnimation(keyPath: "bounds.size.width")` from full width to 0, duration 3.0 s, `fillMode = .forwards`, `isRemovedOnCompletion = false`; ensure all other `update(_:)` branches call `cancelProgressBar.layer?.removeAllAnimations()` and hide the bar in `Wisp/UI/StatusIndicatorView.swift` (depends on T009)
- [x] T011 [P] [US1] Add `private var pendingAudioBuffer: Data?`, `private var shouldPasteAfterProcessing = false`, and `private var cancelCountdownTask: Task<Void, Never>?` properties to `AppDelegate` in `Wisp/App/AppDelegate.swift`
- [x] T012 [US1] Implement `beginCancelCountdown()` in `Wisp/App/AppDelegate.swift`: check `currentSession?.audioDuration < 0.5` → discard path (play stop sound, call `handleResult(.discarded(reason: .tooShort))`); otherwise stop audio capture, store buffer in `pendingAudioBuffer`, play stop sound, transition `recording→cancelling`, show `overlayWindow?.show(state: .cancelling)`, set `shouldPasteAfterProcessing = false`, launch `cancelCountdownTask` (depends on T011)
- [x] T013 [US1] Implement the `cancelCountdownTask` body in `beginCancelCountdown()`: `try await Task.sleep(for: .seconds(3))` wrapped in `do/catch CancellationError`; on expiry — hide overlay, transition `cancelling→processing`, call `transcribeAndSave(audioBuffer: pendingAudioBuffer!)`, clear `pendingAudioBuffer` in `Wisp/App/AppDelegate.swift` (depends on T012)
- [x] T014 [US1] Update `handleEscapeKey()` to call `beginCancelCountdown()` when `state == .recording` (replacing the existing `cancelRecording()` call) in `Wisp/App/AppDelegate.swift` (depends on T012)

**Checkpoint**: User Story 1 is now independently functional. Press Escape during a ≥ 0.5 s recording → "Cancelling..." HUD with draining bar → disappears after 3 s → no paste. Short recordings still silently discard.

---

## Phase 4: User Story 2 — Silent Background Transcription and Log Save (Priority: P2)

**Goal**: When the countdown expires, the transcription result is saved to the log with `wasPasted = false`. Not-pasted entries are visually distinguished in the log window.

**Independent Test**: After a countdown expiry, open the log window and confirm a new entry appears with the correct text and a "not pasted" annotation. Confirmed by `WispTests/TranscriptionLogEntryTests.swift` and `WispTests/TranscriptionLogStoreTests.swift`.

### Tests for User Story 2

> **Write these tests first — confirm they FAIL before writing any implementation.**

- [x] T015 [P] [US2] Create `WispTests/TranscriptionLogEntryTests.swift`; add tests: (a) `TranscriptionLogEntry(text:wasPasted: false)` encodes and decodes `wasPasted` correctly; (b) decoding a JSON object without a `wasPasted` key produces `wasPasted == true` (backward compatibility)
- [x] T016 [P] [US2] Create `WispTests/TranscriptionLogStoreTests.swift`; add test: `append(text: "hello", wasPasted: false)` produces an entry with `wasPasted == false`; `append(text: "hi")` (no explicit flag) produces `wasPasted == true`

### Implementation for User Story 2

- [x] T017 [P] [US2] Add `let wasPasted: Bool` field to `TranscriptionLogEntry` with `init` default of `true`; implement `init(from decoder:)` using `decodeIfPresent(Bool.self, forKey: .wasPasted) ?? true` for backward compatibility in `Wisp/Models/TranscriptionLogEntry.swift`
- [x] T018 [US2] Update `TranscriptionLogStore.append(text:)` to `append(text: String, wasPasted: Bool = true)` and pass the flag to `TranscriptionLogEntry(text:wasPasted:)` in `Wisp/Models/TranscriptionLogStore.swift` (depends on T017)
- [x] T019 [US2] Update `handleResult(.completed)` in `AppDelegate` to call `logStore.append(text: text, wasPasted: shouldPasteAfterProcessing)` then reset `shouldPasteAfterProcessing = false` in `Wisp/App/AppDelegate.swift` (depends on T018)
- [x] T020 [US2] Add a "not pasted" label (`.caption2` font, `.tertiaryLabelColor`, text `"not pasted"`) below the transcription text in `LogView` for entries where `entry.wasPasted == false` in `Wisp/UI/LogView.swift` (depends on T017)

**Checkpoint**: Cancelled transcriptions now appear in the log with `wasPasted = false` and a visible "not pasted" annotation. Normal (pasted) entries are unaffected.

---

## Phase 5: User Story 3 — Second Escape Restores Paste Behaviour (Priority: P2)

**Goal**: Pressing Escape a second time while the countdown is running cancels the countdown and restores the normal transcribe-and-paste flow.

**Independent Test**: Start recording, press Escape (countdown starts), press Escape again → HUD switches to "Transcribing...", result is pasted. Log entry shows `wasPasted = true`. Confirmed by `WispTests/CancelCountdownTests.swift`.

### Tests for User Story 3

> **Write these tests first — confirm they FAIL before writing any implementation.**

- [x] T021 [US3] In `WispTests/CancelCountdownTests.swift`, add test: calling `restoreFromCancelling()` while `state == .cancelling` cancels `cancelCountdownTask`, transitions state to `.processing`, and sets `shouldPasteAfterProcessing == true`

### Implementation for User Story 3

- [x] T022 [US3] Implement `restoreFromCancelling()` in `Wisp/App/AppDelegate.swift`: `cancelCountdownTask?.cancel(); cancelCountdownTask = nil`, set `shouldPasteAfterProcessing = true`, transition `cancelling→processing`, show `overlayWindow?.show(state: .transcribing)`, guard and consume `pendingAudioBuffer`, launch `Task { await transcribeAndPaste(audioBuffer: buffer) }`
- [x] T023 [US3] Update `handleEscapeKey()` to add `else if state == .cancelling { restoreFromCancelling() }` branch in `Wisp/App/AppDelegate.swift` (depends on T022)
- [x] T024 [US3] Ensure `transcribeAndPaste(audioBuffer:)` sets `shouldPasteAfterProcessing = true` before the `handleResult(.completed)` call so the log entry is marked `wasPasted = true` in `Wisp/App/AppDelegate.swift`

**Checkpoint**: All three user stories are independently functional. Full end-to-end flows work correctly.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T025 [P] Verify backward-compatibility: create a test log JSON file without `wasPasted` keys and confirm `TranscriptionLogStore` loads all entries with `wasPasted == true` in `WispTests/TranscriptionLogEntryTests.swift`
- [ ] T026 Run the full manual verification checklist from `specs/005-escape-cancel-countdown/quickstart.md` against the built app
- [x] T027 Remove the old `cancelRecording()` method from `Wisp/App/AppDelegate.swift` if it is now dead code (replaced by `beginCancelCountdown()`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all user story phases**
- **Phase 3 (US1)**: Depends on Phase 2 — must complete before US2 or US3 begin
- **Phase 4 (US2)**: Depends on Phase 3 — builds on the countdown expiry path from US1
- **Phase 5 (US3)**: Depends on Phase 3 — builds on `cancelCountdownTask` and `pendingAudioBuffer` from US1
- **Phase 6 (Polish)**: Depends on all story phases being complete

### User Story Dependencies

- **US1 (P1)**: Requires Foundational only — no dependency on US2 or US3
- **US2 (P2)**: Requires US1's countdown expiry path and `shouldPasteAfterProcessing` flag
- **US3 (P2)**: Requires US1's `cancelCountdownTask` and `pendingAudioBuffer` infrastructure; US2 and US3 are independent of each other and can proceed in parallel once US1 is complete

### Within Each User Story

1. Tests written first (must FAIL before implementation starts)
2. Model/data changes before service/coordinator changes
3. UI changes can proceed in parallel with model changes
4. Integration (`handleEscapeKey` wiring) always last within a story

---

## Parallel Opportunities

### Phase 2 (Foundational)

```text
T002: AppState.cancelling        ║  T003: IndicatorState.cancelling
(Wisp/Models/AppState.swift)     ║  (Wisp/Models/IndicatorState.swift)
```

### Phase 3 (US1) — Test writing

```text
T004: AppStateTests.swift  ║  T005: IndicatorStateTests.swift  ║  T006+T007: CancelCountdownTests.swift
```

### Phase 3 (US1) — Implementation

```text
T008-T010: StatusIndicatorView.swift  ║  T011-T014: AppDelegate.swift
```

### Phase 4 (US2) — Tests + model

```text
T015: TranscriptionLogEntryTests.swift  ║  T016: TranscriptionLogStoreTests.swift
T017: TranscriptionLogEntry.swift       ║  T020: LogView.swift (after T017)
```

---

## Implementation Strategy

### MVP (User Story 1 Only — 14 tasks)

1. Complete Phase 1 (T001)
2. Complete Phase 2 (T002–T003)
3. Complete Phase 3 (T004–T014)
4. **STOP and validate**: Press Escape during recording → countdown HUD → disappears after 3 s → no paste

### Full Delivery

1. MVP (above)
2. Phase 4 → log entries with `wasPasted` flag + "not pasted" annotation in log window
3. Phase 5 → second Escape reversal
4. Phase 6 → polish and backward-compat verification

---

## Notes

- `[P]` tasks touch different files and have no dependency on incomplete tasks in the same phase
- Constitution requires TDD: tests must be **red** before implementation turns them **green**
- `cancelRecording()` (from commit `3eaa047`) is fully replaced by `beginCancelCountdown()` — remove it in T027 once US1 is complete
- `shouldPasteAfterProcessing` starts `false`; `transcribeAndPaste` sets it to `true`, `transcribeAndSave` leaves it `false`; `handleResult` reads it then resets to `false`
- The `CABasicAnimation` in `StatusIndicatorView` runs on the render server — no `Timer` needed for the progress bar; the 3-second timing is authoritative in the `Task.sleep` on `AppDelegate`
