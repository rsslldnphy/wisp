# Feature Specification: Status Indicator GUI

**Feature Branch**: `002-status-indicator-gui`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "Add a simple GUI for visual status indicators. When the app starts up, a loading spinner appears at the bottom center of the screen to indicate model loading. When recording, a recording indicator shows in the same position. When transcribing, a loading indicator shows again. The user should always know what state the app is in."

## Clarifications

### Session 2026-03-28

- Q: Should the indicator appear over fullscreen applications? → A: Indicator appears above fullscreen apps only during recording/transcribing states (not during model loading).
- Q: Should the indicator appear on the primary display or follow the active display? → A: Show on the display containing the currently focused window.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Model Loading Feedback (Priority: P1)

When the user launches the app, a small loading spinner appears at the bottom center of the screen, indicating that the speech recognition model is being loaded. The spinner remains visible until the model is ready. This gives the user confidence that the app is starting up and prevents confusion about whether the app is responsive.

**Why this priority**: Without loading feedback, users may think the app is broken or unresponsive during the model load time, which could take several seconds. This is the first interaction a user has with the app.

**Independent Test**: Can be fully tested by launching the app and observing the spinner appears promptly and disappears once the model is loaded.

**Acceptance Scenarios**:

1. **Given** the app is launching and the model has not yet loaded, **When** the app window appears, **Then** a loading spinner is displayed at the bottom center of the screen with a label indicating model loading is in progress.
2. **Given** the model has finished loading, **When** the loading completes, **Then** the spinner disappears and the app is ready for use.
3. **Given** the app is launched on a slow machine, **When** model loading takes longer than expected, **Then** the spinner continues to animate smoothly without freezing.

---

### User Story 2 - Recording State Indicator (Priority: P1)

When the user activates dictation (starts recording), a visual recording indicator appears at the bottom center of the screen, replacing any previous indicator. This makes it immediately obvious that the app is actively listening and capturing audio.

**Why this priority**: The recording indicator is critical to the core dictation flow. Users must know when the app is listening to speak confidently and to know when to stop.

**Independent Test**: Can be fully tested by triggering a recording session and verifying the recording indicator appears and is visually distinct from the loading state.

**Acceptance Scenarios**:

1. **Given** the model is loaded and the app is idle, **When** the user starts recording, **Then** a recording indicator appears at the bottom center of the screen.
2. **Given** the recording indicator is visible, **When** the user stops recording, **Then** the recording indicator disappears and transitions to the transcribing state.
3. **Given** the recording indicator is displayed, **Then** it is visually distinct from the loading spinner (e.g., different color, animation, or icon) so the user can tell the app is recording, not loading.

---

### User Story 3 - Transcription Loading Indicator (Priority: P1)

After the user stops recording, a loading indicator appears at the bottom center of the screen to show that the audio is being transcribed. This bridges the gap between recording and the transcribed text being pasted, so the user knows processing is happening.

**Why this priority**: Without this indicator, there is a dead period after recording stops where the user has no feedback. This could cause the user to think the app has frozen or to trigger another recording prematurely.

**Independent Test**: Can be fully tested by completing a recording and verifying the transcription loading indicator appears and disappears once transcription completes and text is pasted.

**Acceptance Scenarios**:

1. **Given** the user has just stopped recording, **When** transcription begins, **Then** a loading indicator appears at the bottom center of the screen indicating transcription is in progress.
2. **Given** the transcription loading indicator is visible, **When** transcription completes and text is pasted, **Then** the indicator disappears.
3. **Given** the transcription loading indicator is displayed, **Then** it is visually distinguishable as a "processing" state (not recording, not model loading).

---

### Edge Cases

- What happens if model loading fails? The indicator should show an error state rather than spinning indefinitely.
- What happens if the user triggers recording before the model has finished loading? The app should prevent recording and continue showing the loading state.
- What happens if transcription fails or times out? The indicator should show an error state and then dismiss after a short period.
- What happens if the user triggers a new recording while transcription is still in progress? The app should complete or cancel the current transcription before starting a new recording session.
- What happens if the indicator overlaps with other screen content? The indicator should be unobtrusive and not block user interaction with other applications.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a loading spinner at the bottom center of the screen when the speech recognition model is loading.
- **FR-002**: System MUST display a recording indicator at the bottom center of the screen when audio recording is active.
- **FR-003**: System MUST display a transcription loading indicator at the bottom center of the screen when audio is being transcribed.
- **FR-004**: Each state indicator (loading, recording, transcribing) MUST be visually distinct from the others so the user can immediately identify the current state.
- **FR-005**: System MUST transition between indicator states automatically based on the app's current activity (loading -> idle, idle -> recording, recording -> transcribing, transcribing -> idle).
- **FR-006**: The indicator MUST disappear when the app is idle (model loaded, not recording, not transcribing).
- **FR-007**: System MUST show an error state in the indicator if model loading, recording, or transcription fails.
- **FR-008**: The indicator MUST NOT block user interaction with other applications or the operating system.
- **FR-009**: All indicators MUST appear in a consistent position (bottom center of the screen) across all states.
- **FR-010**: During recording and transcribing states, the indicator MUST appear above fullscreen applications. During model loading, the indicator MUST NOT appear above fullscreen apps.
- **FR-011**: The indicator MUST appear on the display containing the currently focused window, not fixed to the primary display.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify the current app state (loading, recording, transcribing, idle) within 1 second of a state change.
- **SC-002**: The status indicator appears within 0.5 seconds of the app launching.
- **SC-003**: State transitions (loading to idle, idle to recording, recording to transcribing, transcribing to idle) are visually smooth with no jarring jumps or flicker.
- **SC-004**: 100% of state changes in the app are reflected by a corresponding visual indicator change.
- **SC-005**: The indicator does not interfere with the user's ability to interact with other applications while the app is running.

## Assumptions

- The app already has distinct internal states for model loading, recording, and transcribing that can be observed to drive the indicator.
- The indicator is a floating overlay at the bottom center of the screen. It appears above fullscreen apps only during recording and transcribing states.
- The indicator is small and unobtrusive — it provides status at a glance without demanding attention.
- Only one indicator state is shown at a time (states are mutually exclusive in the display).
- The indicator does not require user interaction (no buttons, no dismiss action needed — it appears and disappears automatically).
- The indicator appears on the display containing the currently focused window.
