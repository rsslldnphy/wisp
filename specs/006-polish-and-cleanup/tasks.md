# Tasks: Polish and Cleanup

**Input**: Design documents from `/specs/006-polish-and-cleanup/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No new project setup required — all three changes are additive modifications to the existing Swift package. No dependencies to add; `ServiceManagement` is a system framework.

- [x] T001 Verify `ServiceManagement` framework is imported in `Wisp/App/AppDelegate.swift` (system framework, no Package.swift change needed)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No shared foundational changes are required. Each user story is independently additive. Proceed directly to user story phases.

**Checkpoint**: Foundation ready — all three user stories can begin independently.

---

## Phase 3: User Story 1 — Custom Ghost Logo (Priority: P1) 🎯 MVP

**Goal**: Replace the placeholder SF Symbol idle-state icon with a custom original circular ghost illustration.

**Independent Test**: Build and run the app. In idle state the menu bar icon shows a ghost shape. Toggle dark/light mode — icon remains legible. Start a recording session — icon reverts to `mic.fill` (existing behaviour).

### Implementation for User Story 1

- [x] T002 [US1] Create ghost icon SVG or PDF and add to `Wisp/Resources/Assets.xcassets/StatusBarIcon.imageset/` as a Template Image asset
- [x] T003 [US1] In `Wisp/UI/MenuBarController.swift`, update `updateState(_:)` case `.idle` (and `.cancelling`) to load `NSImage(named: "StatusBarIcon")` with `isTemplate = true` instead of the `"waveform"` SF Symbol
- [ ] T004 [US1] Build and verify the ghost icon renders at menu bar size in both light and dark mode (manual visual check per quickstart.md §1)

**Checkpoint**: User Story 1 complete — custom ghost icon visible in idle state, all other state icons unchanged.

---

## Phase 4: User Story 2 — Fix Beep Captured in Transcript (Priority: P2)

**Goal**: Ensure microphone recording only starts after the start beep has fully played, preventing the beep from being transcribed.

**Independent Test**: Trigger dictation, say nothing for 2 seconds, stop. Transcript is empty. Repeat 5 times — beep never appears. (See quickstart.md §2.)

### Implementation for User Story 2

- [x] T005 [US2] In `Wisp/UI/MenuBarController.swift`, add `NSSoundDelegate` conformance and a stored `startSoundCompletion: (() -> Void)?` property
- [x] T006 [US2] In `Wisp/UI/MenuBarController.swift`, replace `playStartSound()` with `playStartSound(completion: @escaping () -> Void)` — store the closure, set `sound.delegate = self`, call `sound.play()`
- [x] T007 [US2] In `Wisp/UI/MenuBarController.swift`, implement `sound(_:didFinishPlaying:)` — fire and clear `startSoundCompletion`; add a 1000 ms `DispatchWorkItem` fallback that fires the closure if the delegate never calls back (cancel the work item inside the delegate method)
- [x] T008 [US2] In `Wisp/App/AppDelegate.swift`, update the recording-start sequence (around line 306) to call `menuBarController?.playStartSound { [weak self] in self?.audioCaptureService?.startRecording(autoStopHandler: ...) }` instead of calling them sequentially
- [ ] T009 [US2] Build and verify beep-timing fix: trigger dictation 5 times with built-in mic + speakers, confirm beep never appears in transcripts (manual test per quickstart.md §2)

**Checkpoint**: User Story 2 complete — beep no longer captured in transcripts.

---

## Phase 5: User Story 3 — Launch on Startup (Priority: P3)

**Goal**: Add a "Launch on Startup" toggle accessible from both the dropdown menu and Preferences, backed by `SMAppService`.

**Independent Test**: Enable toggle → log out/in → Wisp launches automatically. Disable toggle → log out/in → Wisp does not launch. Toggle reflects correct state after relaunch and after manual System Settings change. (See quickstart.md §3.)

### Implementation for User Story 3

- [x] T010 [P] [US3] In `Wisp/Models/PreferencesStore.swift`, add `launchOnStartup: Bool` property backed by `UserDefaults` key `"launchOnStartup"`, default `false`
- [x] T011 [US3] In `Wisp/Models/PreferencesStore.swift`, add `didSet` on `launchOnStartup` that calls `SMAppService.mainApp.register()` when `true` and `.unregister()` when `false`; catch `SMAppServiceError` and revert the stored value, then post a notification for the UI to show an `NSAlert`
- [x] T012 [US3] In `Wisp/App/AppDelegate.swift`, add `import ServiceManagement` and, in `applicationDidFinishLaunching`, reconcile `PreferencesStore.launchOnStartup` with `SMAppService.mainApp.status` (set stored value to `true` if `.enabled`, `false` otherwise)
- [x] T013 [P] [US3] In `Wisp/UI/PreferencesView.swift`, add a `Toggle("Launch Wisp on Startup", isOn: $preferences.launchOnStartup)` row to the preferences form
- [x] T014 [US3] In `Wisp/App/AppDelegate.swift` `setupMenuBar()`, insert a "Launch on Startup" `NSMenuItem` above the separator; bind its `.state` to `preferencesStore.launchOnStartup` (`.on`/`.off`); wire its action to toggle `preferencesStore.launchOnStartup` (depends on T010, T011)
- [x] T015 [US3] In `Wisp/App/AppDelegate.swift`, ensure the menu item state is refreshed when `NSMenu` is about to open (implement `menuWillOpen(_:)` delegate method to re-read current `SMAppService.mainApp.status`)
- [ ] T016 [US3] Build and verify the full launch-on-startup flow per quickstart.md §3: enable, logout/login, Wisp starts; disable, logout/login, Wisp does not start; manual System Settings removal reconciles correctly

**Checkpoint**: User Story 3 complete — launch-on-startup toggle works end-to-end.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and any cross-story tidy-up.

- [x] T017 [P] Run a full build with strict concurrency checking and confirm zero warnings or errors introduced by this feature
- [ ] T018 Run quickstart.md validation for all three stories end-to-end in a single session
- [x] T019 [P] Confirm `NSSound` delegate object lifetime: ensure no retain cycle between `MenuBarController` and the sound delegate (review `sound.delegate = self` and stored closure)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: N/A — skipped, no shared prerequisites
- **User Stories (Phases 3–5)**: All three are **fully independent** and can proceed in parallel after T001
- **Polish (Phase 6)**: Depends on all three user story phases being complete

### User Story Dependencies

- **US1 (P1)**: Independent — only touches `MenuBarController.swift` and `Assets.xcassets`
- **US2 (P2)**: Independent — touches `MenuBarController.swift` (different methods) and `AppDelegate.swift` (recording sequence only)
- **US3 (P3)**: Independent — touches `PreferencesStore.swift`, `PreferencesView.swift`, and `AppDelegate.swift` (menu setup + launch reconciliation)

*Note*: US2 and US3 both touch `AppDelegate.swift` but in different, non-conflicting locations. They can be worked in parallel by different developers with minimal merge risk.

### Within Each User Story

- US1: Asset creation (T002) before code change (T003)
- US2: Delegate implementation (T005–T007) before call-site update (T008)
- US3: Model (T010–T011) before menu item (T014); reconciliation (T012) can be done in parallel with T013

### Parallel Opportunities

- T010 and T013 (US3 model property + preferences UI) can run in parallel — different files
- All three user story phases can run in parallel if two developers are available
- T017 and T019 (Polish phase) can run in parallel

---

## Parallel Example: User Story 3

```
# Two developers can split US3:
Developer A: T010 → T011 → T012 → T014 → T015  (model + menu item + reconciliation)
Developer B: T013                                 (PreferencesView toggle — independent file)
# Then both: T016 (end-to-end verification)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001 (setup check)
2. Complete Phase 3 (T002–T004): Ghost icon
3. **STOP and VALIDATE**: Menu bar shows ghost icon in both modes
4. Ship / demo

### Incremental Delivery

1. T001 → US1 (T002–T004) → visual validation
2. US2 (T005–T009) → beep fix validation
3. US3 (T010–T016) → startup toggle validation
4. Phase 6 polish (T017–T019)

### Parallel Team Strategy

With two developers:
- Dev A: US1 (ghost icon) + US2 (beep fix) in sequence
- Dev B: US3 (launch on startup) independently
- Both join for Phase 6 polish

---

## Notes

- [P] tasks = different files, no blocking dependencies
- [Story] label maps each task to its user story for traceability
- Each user story is independently completable and testable without the others
- No test tasks generated: spec does not request TDD; verification steps are manual per quickstart.md
- Commit after each user story phase checkpoint before moving to the next
