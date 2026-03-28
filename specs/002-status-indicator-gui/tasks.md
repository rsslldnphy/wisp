# Tasks: Status Indicator GUI

**Input**: Design documents from `/specs/002-status-indicator-gui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Included per constitution Principle III (Test-First Development).

**Organization**: Tasks grouped by user story. All three stories are P1 but organized sequentially since they share the overlay infrastructure.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: No new project setup needed — existing project structure is used. This phase handles only the shared model changes.

- [x] T001 Add `.loading` case to `AppState` enum and update transition rules (`.loading -> .idle`, block `.loading -> .recording`) in Wisp/Models/AppState.swift
- [x] T002 Add tests for new `.loading` state transitions (loading->idle succeeds, loading->recording fails, loading->processing fails) in WispTests/AppStateTests.swift

**Checkpoint**: AppState now models the loading phase. All existing tests still pass.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the overlay window and indicator view infrastructure that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Create `IndicatorState` enum (`.modelLoading`, `.recording`, `.transcribing`, `.error(String)`, `.hidden`) in Wisp/Models/IndicatorState.swift
- [x] T004 Write tests for `IndicatorState` mapping from `AppState` (each AppState maps to correct IndicatorState) in WispTests/IndicatorStateTests.swift
- [x] T005 Create `StatusOverlayWindow` (NSPanel subclass): borderless, non-activating, click-through, `ignoresMouseEvents = true`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`, positioned at bottom center of `NSScreen.main` in Wisp/UI/StatusOverlayWindow.swift
- [x] T006 Write tests for `StatusOverlayWindow`: verify window level defaults to `.floating`, verify `ignoresMouseEvents` is true, verify positioning calculation returns bottom center of a given screen frame in WispTests/StatusOverlayWindowTests.swift
- [x] T007 Create `StatusIndicatorView` (NSView subclass): pill-shaped background using `NSVisualEffectView` with dark material, rounded corners (height/2), horizontal stack of icon area + label in Wisp/UI/StatusIndicatorView.swift
- [x] T008 Write tests for `StatusIndicatorView`: verify `update(_:)` method sets correct label text for each `IndicatorState`, verify `.hidden` state hides the view in WispTests/StatusIndicatorViewTests.swift

**Checkpoint**: Overlay window and indicator view exist and can be shown/hidden. Not yet wired to app state.

---

## Phase 3: User Story 1 — Model Loading Feedback (Priority: P1) 🎯 MVP

**Goal**: When the app launches, a loading spinner appears at bottom center of screen during model loading, then disappears when ready.

**Independent Test**: Launch app → spinner visible at bottom center → model loads → spinner disappears.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T009 [US1] Write test: when AppDelegate sets state to `.loading`, StatusIndicatorView shows spinner animation and "Loading model..." label in WispTests/StatusIndicatorViewTests.swift
- [x] T010 [US1] Write test: when state transitions from `.loading` to `.idle`, overlay window hides (orderOut) in WispTests/StatusOverlayWindowTests.swift

### Implementation for User Story 1

- [x] T011 [US1] Implement model-loading indicator rendering in `StatusIndicatorView.update(_:)`: for `.modelLoading`, show `NSProgressIndicator` (spinning style) + "Loading model..." label in Wisp/UI/StatusIndicatorView.swift
- [x] T012 [US1] Add `show(state:)` and `hide()` methods to `StatusOverlayWindow` that set window level to `.floating`, position to bottom center of `NSScreen.main`, and call `orderFront`/`orderOut` in Wisp/UI/StatusOverlayWindow.swift
- [x] T013 [US1] Wire overlay to AppDelegate: create `StatusOverlayWindow` in `applicationDidFinishLaunching`, set initial state to `.loading`, show overlay. On model load completion, transition to `.idle` and hide overlay in Wisp/App/AppDelegate.swift
- [x] T014 [US1] Update `MenuBarController.updateState(_:)` to handle `.loading` case with "hourglass" SF Symbol icon in Wisp/UI/MenuBarController.swift

**Checkpoint**: App launches with loading spinner at bottom center. Spinner disappears when model is ready. Menu bar icon reflects loading state.

---

## Phase 4: User Story 2 — Recording State Indicator (Priority: P1)

**Goal**: When recording starts, a visually distinct recording indicator (pulsing red dot) appears at bottom center, above fullscreen apps.

**Independent Test**: Press Option+Space → red pulsing recording indicator appears → release → indicator transitions away.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T015 [US2] Write test: when `StatusIndicatorView` receives `.recording` state, it shows a red dot element and "Recording..." label (distinct from loading spinner) in WispTests/StatusIndicatorViewTests.swift
- [x] T016 [US2] Write test: when `StatusOverlayWindow.show(state:)` is called with `.recording`, window level is set above fullscreen (`.screenSaver` or equivalent) in WispTests/StatusOverlayWindowTests.swift

### Implementation for User Story 2

- [x] T017 [US2] Implement recording indicator rendering in `StatusIndicatorView.update(_:)`: for `.recording`, show red circle (CALayer with pulse animation via `CABasicAnimation`) + "Recording..." label in Wisp/UI/StatusIndicatorView.swift
- [x] T018 [US2] Update `StatusOverlayWindow.show(state:)` to set window level to above-fullscreen (`NSWindow.Level.screenSaver` or `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))`) when state is `.recording` in Wisp/UI/StatusOverlayWindow.swift
- [x] T019 [US2] Wire recording state to overlay in AppDelegate: when `startRecording()` succeeds, call `overlayWindow.show(state: .recording)`. Recalculate position on `NSScreen.main` at show time in Wisp/App/AppDelegate.swift

**Checkpoint**: Recording shows pulsing red dot indicator. Visible above fullscreen apps. Visually distinct from loading spinner.

---

## Phase 5: User Story 3 — Transcription Loading Indicator (Priority: P1)

**Goal**: After recording stops, a transcription loading indicator appears at bottom center (above fullscreen) until text is pasted.

**Independent Test**: Stop recording → transcription spinner appears → transcription completes → spinner disappears.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T020 [US3] Write test: when `StatusIndicatorView` receives `.transcribing` state, it shows a spinner and "Transcribing..." label (visually distinct from model loading and recording) in WispTests/StatusIndicatorViewTests.swift
- [x] T021 [US3] Write test: when `StatusOverlayWindow.show(state:)` is called with `.transcribing`, window level is above fullscreen (same as recording) in WispTests/StatusOverlayWindowTests.swift

### Implementation for User Story 3

- [x] T022 [US3] Implement transcribing indicator rendering in `StatusIndicatorView.update(_:)`: for `.transcribing`, show `NSProgressIndicator` (spinning) + "Transcribing..." label. Use a different tint/style than model loading to distinguish states in Wisp/UI/StatusIndicatorView.swift
- [x] T023 [US3] Wire transcribing state to overlay in AppDelegate: when `stopRecordingAndTranscribe()` transitions to `.processing`, call `overlayWindow.show(state: .transcribing)`. On `handleResult()`, call `overlayWindow.hide()` in Wisp/App/AppDelegate.swift

**Checkpoint**: Full flow works: loading spinner → idle (hidden) → recording indicator → transcribing spinner → idle (hidden).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Error states, active display tracking, edge cases, and smoothness.

- [x] T024 [P] Implement error state rendering in `StatusIndicatorView.update(_:)`: for `.error(message)`, show exclamation icon + error message label. Auto-dismiss after 3 seconds via `DispatchWorkItem` in Wisp/UI/StatusIndicatorView.swift
- [x] T025 [P] Wire error states in AppDelegate: on model load failure, show `.error("Model failed to load")` then retry or return to loading. On transcription failure, show `.error(message)` then return to idle in Wisp/App/AppDelegate.swift
- [x] T026 [P] Add active display tracking: observe `NSApplication.didChangeScreenParametersNotification` in `StatusOverlayWindow` to recalculate position when displays change. Recalculate position on every `show(state:)` call using `NSScreen.main` in Wisp/UI/StatusOverlayWindow.swift
- [x] T027 [P] Add smooth fade transitions between indicator states using `NSAnimationContext` or `CATransaction` with 0.2s duration in Wisp/UI/StatusIndicatorView.swift
- [x] T028 [P] Write test for error auto-dismiss: verify `.error` state triggers a 3-second timer that transitions to `.hidden` in WispTests/StatusIndicatorViewTests.swift
- [x] T029 Block hotkey during loading: in AppDelegate `handleHotkeyToggle()`, add `.loading` case that prints a message and ignores the keypress (recording blocked until model ready) in Wisp/App/AppDelegate.swift
- [ ] T030 Run quickstart.md validation: manually test full flow per quickstart.md scenarios (launch, record, transcribe, fullscreen, multi-display)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 for AppState changes)
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion
- **User Story 2 (Phase 4)**: Depends on Phase 2 completion. Can run in parallel with US1 but shares files — recommend sequential after US1
- **User Story 3 (Phase 5)**: Depends on Phase 2 completion. Sequential after US2 (shares AppDelegate wiring)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — establishes the overlay show/hide pattern
- **User Story 2 (P1)**: Builds on US1's overlay infrastructure — adds recording-specific rendering and window level toggling
- **User Story 3 (P1)**: Builds on US2's above-fullscreen window level — adds transcribing-specific rendering

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- View rendering before AppDelegate wiring
- Core implementation before integration

### Parallel Opportunities

- T003 and T005 can run in parallel (different files: IndicatorState.swift vs StatusOverlayWindow.swift)
- T004 and T006 can run in parallel (different test files)
- T005 and T007 can run in parallel (different files: StatusOverlayWindow.swift vs StatusIndicatorView.swift)
- All Polish phase tasks (T024-T029) marked [P] can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch model + window creation in parallel:
Task: "T003 Create IndicatorState enum in Wisp/Models/IndicatorState.swift"
Task: "T005 Create StatusOverlayWindow in Wisp/UI/StatusOverlayWindow.swift"
Task: "T007 Create StatusIndicatorView in Wisp/UI/StatusIndicatorView.swift"

# Then tests in parallel:
Task: "T004 Write IndicatorState tests"
Task: "T006 Write StatusOverlayWindow tests"
Task: "T008 Write StatusIndicatorView tests"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: AppState extension
2. Complete Phase 2: Overlay window + indicator view infrastructure
3. Complete Phase 3: Model loading spinner
4. **STOP and VALIDATE**: Launch app, confirm spinner appears and disappears
5. Proceed to US2 and US3

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Add US1 → Loading spinner works → Validate (MVP!)
3. Add US2 → Recording indicator works → Validate
4. Add US3 → Transcribing indicator works → Validate (full flow!)
5. Add Polish → Error states, transitions, edge cases → Final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Constitution requires TDD — all test tasks must be completed before their corresponding implementation tasks
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
