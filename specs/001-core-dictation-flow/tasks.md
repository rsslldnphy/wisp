# Tasks: Core Dictation Flow

**Input**: Design documents from `/specs/001-core-dictation-flow/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Included per Constitution III (Test-First Development). Tests MUST be written and fail before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Xcode project initialization and dependency configuration

- [x] T001 Create Xcode project "Wisp" as macOS App target with Swift 6.2+, set LSUIElement=YES in Info.plist, configure strict concurrency checking in build settings at Package.swift
- [x] T002 Add WhisperKit (Argmax) and KeyboardShortcuts (Sindre Sorhus) as Swift Package Manager dependencies in Package.swift
- [x] T003 [P] Create project directory structure: Wisp/App/, Wisp/Models/, Wisp/Services/, Wisp/UI/, Wisp/Resources/Sounds/, WispTests/Unit/, WispTests/Integration/, WispTests/Fixtures/
- [x] T004 [P] Add audio fixture files for testing: WispTests/Fixtures/hello-world.wav (known phrase), WispTests/Fixtures/silence.wav (no speech), WispTests/Fixtures/short-clip.wav (<0.5s)
- [x] T005 [P] Add audio cue sound files: Wisp/Resources/Sounds/record-start.wav and Wisp/Resources/Sounds/record-stop.wav (short, distinct, <0.5s each)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and state machine that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Write unit tests for AppState state machine transitions (idle→recording, recording→processing, processing→idle, invalid transitions ignored) in WispTests/Unit/AppStateTests.swift
- [x] T007 Implement AppState enum with transition validation logic in Wisp/Models/AppState.swift
- [x] T008 Write unit tests for TranscriptionResult, DiscardReason, and TranscriptionError enums in WispTests/Unit/TranscriptionResultTests.swift
- [x] T009 [P] Implement TranscriptionResult enum (completed/discarded/failed), DiscardReason enum (tooShort/noSpeechDetected), and TranscriptionError enum in Wisp/Models/TranscriptionResult.swift
- [x] T010 [P] Write unit tests for DictationSession lifecycle (creation, duration tracking, result assignment) in WispTests/Unit/DictationSessionTests.swift
- [x] T011 Implement DictationSession struct (id, startTime, endTime, audioDuration, result) in Wisp/Models/DictationSession.swift
- [x] T012 Create app entry point WispApp with AppDelegate setup in Wisp/App/WispApp.swift
- [x] T013 Implement AppDelegate with NSStatusItem menu bar setup and microphone/accessibility permission requests on first launch in Wisp/App/AppDelegate.swift

**Checkpoint**: Foundation ready — models compile, state machine tested, app launches as menu bar icon

---

## Phase 3: User Story 1 — Basic Dictation (Priority: P1) MVP

**Goal**: User presses Option+Space to start recording, presses again to stop, audio is transcribed locally, text is pasted at cursor.

**Independent Test**: Launch app, press hotkey in TextEdit, speak "Hello world", press hotkey, verify transcribed text appears.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T014 [P] [US1] Write unit tests for AudioCaptureService (start/stop recording, buffer accumulation, 16kHz format, 5-min auto-stop, <0.5s discard) using mock audio buffers in WispTests/Unit/AudioCaptureServiceTests.swift
- [x] T015 [P] [US1] Write unit tests for TranscriptionService (transcribe audio buffer, handle model-not-loaded, handle empty audio) in WispTests/Unit/TranscriptionServiceTests.swift
- [x] T016 [P] [US1] Write unit tests for TextCleanupService (punctuation preserved, filler words removed, capitalization intact, meaning preserved) in WispTests/Unit/TextCleanupServiceTests.swift
- [x] T017 [P] [US1] Write unit tests for PasteService (paste to focused field, clipboard fallback when no text field, transient pasteboard marking) in WispTests/Unit/PasteServiceTests.swift
- [x] T018 [P] [US1] Write unit tests for HotkeyService (register/unregister hotkey, callback invocation) in WispTests/Unit/HotkeyServiceTests.swift

### Implementation for User Story 1

- [x] T019 [US1] Implement HotkeyService wrapping KeyboardShortcuts with default Option+Space, register/unregister, and callback on toggle in Wisp/Services/HotkeyService.swift
- [x] T020 [US1] Implement AudioCaptureService using AVAudioEngine: start recording (16kHz mono float32), accumulate buffers in memory, stop recording, enforce 5-minute max with Timer, discard if <0.5s in Wisp/Services/AudioCaptureService.swift
- [x] T021 [US1] Implement TranscriptionService wrapping WhisperKit: load model on init, transcribe audio buffer async, return transcribed text or error in Wisp/Services/TranscriptionService.swift
- [x] T022 [US1] Implement TextCleanupService using Apple Foundation Models (on-device LLM): remove filler words, fix punctuation, preserve meaning in Wisp/Services/TextCleanupService.swift
- [x] T023 [US1] Implement PasteService: write text to NSPasteboard with transient type marker, detect focused text field via AXUIElement, simulate Cmd+V via CGEvent with 75ms delay, fall back to clipboard-only with notification if no text field in Wisp/Services/PasteService.swift
- [x] T024 [US1] Wire the full dictation flow in AppDelegate: hotkey toggle → state transition → start/stop AudioCaptureService → TranscriptionService → TextCleanupService → PasteService → return to idle in Wisp/App/AppDelegate.swift
- [x] T025 [US1] Write integration test for full dictation pipeline: fixture audio → TranscriptionService → TextCleanupService → verify output text in WispTests/Integration/TranscriptionPipelineTests.swift

**Checkpoint**: User Story 1 fully functional — hotkey triggers record → transcribe → paste cycle

---

## Phase 4: User Story 2 — Recording Feedback (Priority: P2)

**Goal**: Menu bar icon and audio cues provide clear feedback for idle, recording, and processing states.

**Independent Test**: Observe menu bar icon transitions through idle → recording → processing → idle, verify each is visually distinct and audio cues play.

### Tests for User Story 2

- [x] T026 [P] [US2] Write unit tests for MenuBarController (icon updates on state change: idle/recording/processing, returns to idle within 1s of completion) in WispTests/Unit/MenuBarControllerTests.swift

### Implementation for User Story 2

- [x] T027 [P] [US2] Create three distinct menu bar icon assets (idle, recording, processing) as SF Symbols in Wisp/UI/MenuBarController.swift
- [x] T028 [US2] Implement MenuBarController: observe AppState changes, update NSStatusItem image for each state, play record-start.wav before recording begins and record-stop.wav after recording stops in Wisp/UI/MenuBarController.swift
- [x] T029 [US2] Integrate MenuBarController with AppDelegate: bind state transitions to icon updates and audio cue playback in Wisp/App/AppDelegate.swift

**Checkpoint**: Menu bar shows distinct icons for each state, audio cues play on start/stop

---

## Phase 5: User Story 3 — Error Recovery (Priority: P3)

**Goal**: All error conditions show user-facing notifications and return to idle without requiring restart.

**Independent Test**: Disconnect microphone, attempt dictation, verify notification appears and app returns to idle. Record <0.5s, verify "Recording too short" notification.

### Tests for User Story 3

- [x] T030 [P] [US3] Write unit tests for error notification paths: microphone unavailable, recording too short, transcription failure, no speech detected, permission denied — each must trigger notification and return to idle in WispTests/Unit/ErrorHandlingTests.swift

### Implementation for User Story 3

- [x] T031 [US3] Implement notification helper: display macOS user notifications for error messages with appropriate titles per error type in Wisp/Services/NotificationService.swift
- [x] T032 [US3] Add error handling to AudioCaptureService: detect microphone unavailable, check permission status, handle recording too short (<0.5s discard with DiscardReason.tooShort) in Wisp/Services/AudioCaptureService.swift
- [x] T033 [US3] Add error handling to TranscriptionService: detect no speech in audio (DiscardReason.noSpeechDetected), handle model load failures, wrap runtime errors in TranscriptionError in Wisp/Services/TranscriptionService.swift
- [x] T034 [US3] Wire error paths in AppDelegate: catch all error types from services, display notification via NotificationService, transition to idle state in Wisp/App/AppDelegate.swift
- [x] T035 [US3] Add microphone permission monitoring: detect runtime revocation via AVCaptureDevice authorization status changes, stop active recording and notify user in Wisp/App/AppDelegate.swift
- [x] T036 [US3] Write integration test for error recovery flow: simulate microphone disconnect during recording, verify notification and state returns to idle in WispTests/Integration/DictationFlowTests.swift

**Checkpoint**: All error conditions handled — app always recovers to idle with user notification

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and improvements across all user stories

- [ ] T037 [P] Run quickstart.md validation: build from clean checkout, launch, complete full dictation cycle in TextEdit per specs/001-core-dictation-flow/quickstart.md
- [ ] T038 [P] Verify idle memory usage is under 50 MB (unload WhisperKit model when not transcribing)
- [ ] T039 [P] Verify hotkey response time is under 200 ms from keypress to recording start
- [x] T040 Run full test suite (unit + integration) and verify all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Phase 3): Can start after Foundational
  - US2 (Phase 4): Can start after Foundational (independent of US1)
  - US3 (Phase 5): Can start after Foundational (independent of US1/US2)
- **Polish (Phase 6)**: Depends on all user stories being complete

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models/enums before services
- Services before integration/wiring
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T003, T004, T005)
- All Foundational model tasks marked [P] can run in parallel (T009, T010)
- All US1 test tasks marked [P] can run in parallel (T014-T018)
- US2 icon creation (T027) can run in parallel with US2 tests (T026)
- Once Foundational completes, US1, US2, and US3 can start in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Full dictation cycle works in TextEdit
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test dictation cycle → MVP!
3. Add User Story 2 → Test visual/audio feedback
4. Add User Story 3 → Test error handling
5. Polish → Performance validation, full test suite

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Constitution III requires TDD: all test tasks must complete and fail before corresponding implementation
- Audio cue playback (T028) must play start sound BEFORE recording begins (so it isn't captured)
- PasteService (T023) needs 75ms delay between pasteboard write and CGEvent post
- WhisperKit model should be unloaded when idle to meet <50MB memory target
- TextCleanupService uses Apple Foundation Models (on-device LLM) instead of regex — requires macOS 26+
