# Tasks: Configuration Screen

**Input**: Design documents from `/specs/003-config-screen/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included — the Wisp constitution (Principle III) mandates test-first development. Tests MUST be written and confirmed failing before the corresponding implementation task begins.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All paths are relative to the repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the KeyboardShortcuts dependency and define the shortcut name that all downstream tasks depend on.

- [x] T001 Add `KeyboardShortcuts` (Sindre Sorhus, v2.x) to `Package.swift` dependencies and `Wisp` target; run `swift package resolve` to fetch
- [x] T002 [P] Create `Wisp/Models/ShortcutNames.swift` defining `KeyboardShortcuts.Name.toggleDictation` with default `.init(.space, modifiers: .option)`

**Checkpoint**: `swift build` passes with KeyboardShortcuts imported; `ShortcutNames.swift` compiles cleanly.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: `PreferencesStore` is the single source of truth consumed by every user story. It must be complete before any service or UI work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Write `WispTests/Unit/PreferencesStoreTests.swift`: happy-path tests for `cleanupPrompt` read/write/reset, `selectedMicrophoneUID` read/write/reset-to-nil, and `defaultCleanupPrompt` constant; failure-path tests for `emptyPrompt` error on blank/whitespace input and corrupted-UserDefaults fallback to default prompt — confirm all tests **fail** before T004
- [x] T004 Create `Wisp/Models/PreferencesStore.swift`: actor implementing the full interface in `contracts/preferences-store.md`, UserDefaults keys `com.wisp.cleanupPrompt` and `com.wisp.selectedMicrophoneUID`, `PreferencesError.emptyPrompt`, and `defaultCleanupPrompt` constant equal to the prompt currently hardcoded in `TextCleanupService.swift`

**Checkpoint**: All `PreferencesStoreTests` pass. `swift build` succeeds.

---

## Phase 3: User Story 1 — Change Recording Keyboard Shortcut (Priority: P1) 🎯 MVP

**Goal**: User can open a preferences panel from the menu bar and record a new keyboard shortcut that immediately replaces the hardcoded Option+Space for toggling dictation.

**Independent Test**: Open preferences, record a new shortcut (e.g., Cmd+Shift+D), close preferences, verify the new shortcut triggers dictation and Option+Space does not.

### Tests for User Story 1

> **Write these tests FIRST — they must fail before implementation begins**

- [x] T005 [US1] Update `WispTests/Unit/HotkeyServiceTests.swift`: replace/extend existing tests to verify that `HotkeyService` invokes `onToggle` via `KeyboardShortcuts.onKeyDown(for: .toggleDictation)` and that no hardcoded key-code (49 / Option) check remains

### Implementation for User Story 1

- [x] T006 [US1] Update `Wisp/Services/HotkeyService.swift`: remove CGEventTap creation and raw key-code check; replace `startListening()` body with `KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in self?.onToggle() }`; remove Accessibility-permission request from `HotkeyService` (library manages it)
- [x] T007 [P] [US1] Create `Wisp/UI/PreferencesWindow.swift`: `NSWindowController` subclass with singleton `shared` instance, `showWindow(_:)` brings existing window to front rather than opening a second, titled "Wisp Preferences", minimum size 480 × 360 pt, hosts a SwiftUI `NSHostingView<PreferencesView>`
- [x] T008 [US1] Create `Wisp/UI/PreferencesView.swift`: SwiftUI `Form` with a "Recording Shortcut" section containing `KeyboardShortcuts.Recorder("Toggle Dictation", name: .toggleDictation)` and an inline error label shown when the recorder reports an empty shortcut; stub out remaining two sections (microphone, prompt) with placeholder `Text` views
- [x] T009 [US1] Update `Wisp/App/AppDelegate.swift`: instantiate `PreferencesStore`, add "Preferences…" `NSMenuItem` above "Quit Wisp" in the status bar menu with action that calls `PreferencesWindow.shared.showWindow(nil)`, inject `PreferencesStore` into `HotkeyService` initialiser (even if US1 does not yet use it — sets the pattern for US2/US3)

**Checkpoint**: App builds and runs. "Preferences…" appears in the status bar menu. Opening it shows the shortcut recorder. Recording a new shortcut makes dictation respond to the new key and not to Option+Space. Closing and re-opening the window brings the same instance to front. All `HotkeyServiceTests` pass.

---

## Phase 4: User Story 2 — Switch Microphone Input (Priority: P2)

**Goal**: User can select any connected audio input device from the preferences panel; the next dictation session uses the chosen device. The list refreshes automatically when devices are connected or disconnected while the panel is open.

**Independent Test**: Connect a second microphone, open preferences, select it, close preferences, start dictation, confirm audio captured from the selected device. Disconnect it while preferences is open — list updates immediately and shows empty-state message if no others remain.

### Tests for User Story 2

> **Write these tests FIRST — they must fail before implementation begins**

- [x] T010 [P] [US2] Write `WispTests/Unit/MicrophoneEnumerationTests.swift`: tests for `MicrophoneList` — populated device list, empty-list state when no devices present, device added/removed events updating `devices`, `selectedUID` reset to `nil` when the selected device disconnects
- [x] T011 [P] [US2] Extend `WispTests/Unit/AudioCaptureServiceTests.swift`: tests for `AudioCaptureService` accepting a non-nil `selectedMicrophoneUID` from `PreferencesStore` and calling the CoreAudio device-switch helper before `AVAudioEngine.start()`

### Implementation for User Story 2

- [x] T012 [P] [US2] Create `Wisp/Models/MicrophoneDevice.swift`: `Sendable` struct with `uid: String`, `displayName: String`, `isDefault: Bool` per data-model.md; identity based on `uid`
- [x] T013 [US2] Create `Wisp/Models/MicrophoneList.swift`: actor with `devices: [MicrophoneDevice]` and `selectedUID: String?`; enumerate CoreAudio input-capable devices via `kAudioHardwarePropertyDevices` + `kAudioDevicePropertyScopeInput` stream check on `init`; register `AudioObjectAddPropertyListener` on `kAudioObjectSystemObject` / `kAudioHardwarePropertyDevices` for hot-plug; publish device-list changes via `AsyncStream`; set `selectedUID = nil` when the selected device disconnects; write `selectedUID` changes to `PreferencesStore` (depends on T012)
- [x] T014 [US2] Update `Wisp/Services/AudioCaptureService.swift`: add `init(preferences: PreferencesStore)`; in `startRecording()`, `await preferences.selectedMicrophoneUID` and — if non-nil — resolve the CoreAudio `AudioDeviceID` by UID and set `kAudioOutputUnitProperty_CurrentDevice` on `engine.inputNode.audioUnit` before calling `engine.start()`; nil UID leaves default device unchanged
- [x] T015 [US2] Add microphone picker section to `Wisp/UI/PreferencesView.swift`: replace microphone stub with a `Picker` bound to `MicrophoneList.selectedUID` listing `MicrophoneDevice.displayName` values keyed by `uid`; when `MicrophoneList.devices` is empty show `Text("No microphones detected")` and disable the picker; observe `MicrophoneList` device stream to refresh automatically
- [x] T016 [US2] Update `Wisp/App/AppDelegate.swift`: instantiate `MicrophoneList`, inject into `PreferencesView`; inject updated `AudioCaptureService(preferences:)` in place of the old initialiser

**Checkpoint**: App builds. Preferences panel shows connected microphones in a dropdown. Selecting one persists across app restart. Plugging/unplugging a device updates the list live. Empty-state message appears when no device is connected. All `MicrophoneEnumerationTests` and new `AudioCaptureServiceTests` pass.

---

## Phase 5: User Story 3 — Amend the Transcription Cleanup Prompt (Priority: P3)

**Goal**: User can read and edit the LLM cleanup prompt in the preferences panel; the updated prompt is used for all subsequent dictation sessions. A "Reset to Default" action restores the original prompt. Saving an empty prompt is blocked with an inline error.

**Independent Test**: Open preferences, edit the prompt to include "always respond in bullet points", close preferences, dictate something, verify the cleaned output is formatted as bullets. Clear the prompt — save is blocked. Click "Reset to Default" — original prompt is restored.

### Tests for User Story 3

> **Write these tests FIRST — they must fail before implementation begins**

- [x] T017 [US3] Update `WispTests/Unit/TextCleanupServiceTests.swift`: add/replace tests verifying that `TextCleanupService` reads `cleanupPrompt` from `PreferencesStore` at call time (not at init time) and that a changed prompt is used on the next call without restarting the service

### Implementation for User Story 3

- [x] T018 [US3] Update `Wisp/Services/TextCleanupService.swift`: add `init(preferences: PreferencesStore)`; in `clean(_ text: String)`, replace hardcoded prompt literal with `await preferences.cleanupPrompt`; remove the hardcoded prompt constant from this file (it now lives in `PreferencesStore.defaultCleanupPrompt`)
- [x] T019 [US3] Add prompt editor section to `Wisp/UI/PreferencesView.swift`: replace prompt stub with a multi-line `TextEditor` (min height 120 pt) bound to a local `@State` draft string; on focus-loss commit to `PreferencesStore` via `setCleanupPrompt(_:)` and surface `PreferencesError.emptyPrompt` as an inline error label; add a "Reset to Default" `Button` (link style) that calls `PreferencesStore.resetCleanupPrompt()` and clears any validation error
- [x] T020 [US3] Update `Wisp/App/AppDelegate.swift`: replace `TextCleanupService()` construction with `TextCleanupService(preferences: preferencesStore)`

**Checkpoint**: App builds. Preferences panel shows editable prompt text area. Editing and closing applies the new prompt to the next dictation. Clearing the field shows the inline error and preserves the previous prompt. "Reset to Default" restores original text. All updated `TextCleanupServiceTests` pass.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalise shared UX behaviour and validate the complete feature end-to-end.

- [x] T021 Implement dismiss-without-saving behaviour in `Wisp/UI/PreferencesWindow.swift` and `Wisp/UI/PreferencesView.swift`: Escape key and the window close button discard any in-flight `TextEditor` draft that has not yet been committed to `PreferencesStore`; shortcut and microphone changes already commit immediately so no discard logic is needed for those
- [x] T022 [P] Run the end-to-end verification steps in `quickstart.md` against the built app; document and fix any integration gaps found

**Checkpoint**: All seven quickstart verification steps pass. All unit test suites pass. `swift build` produces no warnings beyond pre-existing ones.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **blocks all user story phases**
- **US1 (Phase 3)**: Depends on Phase 2; no dependency on US2 or US3
- **US2 (Phase 4)**: Depends on Phase 2; no dependency on US1 or US3 (integrates with US1's PreferencesWindow/View, but US1 stubs allow parallel start)
- **US3 (Phase 5)**: Depends on Phase 2; no dependency on US1 or US2 (shares PreferencesStore)
- **Polish (Phase 6)**: Depends on all desired user story phases

### User Story Dependencies

- **US1 (P1)**: Can start immediately after Phase 2 — no dependency on other stories
- **US2 (P2)**: Can start after Phase 2 — borrows PreferencesWindow/View shell from US1 but can stub it
- **US3 (P3)**: Can start after Phase 2 — only needs PreferencesStore and TextCleanupService

### Within Each User Story

- Tests MUST be written and confirmed **failing** before implementation
- Models/structs before actors that depend on them
- Actors/services before UI sections that observe them
- Service injection in AppDelegate last (after service and UI are complete)

### Parallel Opportunities

- T001 and T002 can run in parallel (Package.swift vs ShortcutNames.swift)
- T010 and T011 can run in parallel (different test files, Phase 4 setup)
- T012 and T010/T011 can all run in parallel (struct creation vs test writing)
- T007 (PreferencesWindow shell) can proceed concurrently with T005 (HotkeyService tests)
- Once Phase 2 completes, US1, US2, US3 can be worked in parallel by separate developers

---

## Parallel Example: User Story 2

```text
# After T009 (AppDelegate US1 wiring) is done, these can start in parallel:
T010: Write MicrophoneEnumerationTests.swift
T011: Extend AudioCaptureServiceTests.swift
T012: Create MicrophoneDevice.swift

# Then sequentially:
T013: Create MicrophoneList.swift       ← depends on T012
T014: Update AudioCaptureService.swift  ← depends on T013 + T011 failing
T015: Add microphone section to PreferencesView.swift  ← depends on T013
T016: Wire AppDelegate.swift            ← depends on T014, T015
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T004)
3. Complete Phase 3: User Story 1 (T005–T009)
4. **STOP and validate**: new shortcut works, Option+Space is gone, preferences window opens/closes correctly
5. Ship or demo as MVP

### Incremental Delivery

1. Setup + Foundational → PreferencesStore and KeyboardShortcuts wired
2. US1 → configurable shortcut works → MVP
3. US2 → microphone selection works → incremental release
4. US3 → editable cleanup prompt works → full feature complete
5. Polish → validated end-to-end

---

## Notes

- `[P]` tasks operate on different files with no incomplete shared dependencies
- `[Story]` labels map tasks to specific user stories for traceability
- Constitution Principle III is non-negotiable: all tests must be red before implementation begins
- Commit after each task or logical group; every commit must compile and pass tests (constitution Principle: Development Workflow)
- AppDelegate wiring tasks (T009, T016, T020) are always last within each story — they depend on both the service and UI being ready
