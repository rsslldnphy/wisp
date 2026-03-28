# Feature Specification: Core Dictation Flow

**Feature Branch**: `001-core-dictation-flow`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "core dictation flow. record audio when option space pressed, stop when option space pressed again, transcribe with local whisper model, paste result"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Dictation (Priority: P1)

The user is working in any application (text editor, browser, chat app)
and wants to dictate text instead of typing. They press Option+Space to
begin recording. A visual indicator appears in the menu bar confirming
that recording is active. The user speaks naturally. When finished, they
press Option+Space again to stop recording. The app transcribes the
recorded audio using a local speech-to-text model and automatically
pastes the transcribed text at the current cursor position in the
active application.

**Why this priority**: This is the entire core value proposition of
Wisp. Without this flow, the app has no purpose.

**Independent Test**: Can be fully tested by launching the app,
pressing the hotkey in any text field, speaking a known phrase,
pressing the hotkey again, and verifying the transcribed text
appears at the cursor.

**Acceptance Scenarios**:

1. **Given** the app is running in the menu bar and no recording is active, **When** the user presses Option+Space, **Then** audio recording begins from the system microphone and a visual indicator shows recording is active.
2. **Given** audio recording is active, **When** the user presses Option+Space again, **Then** recording stops, the audio is transcribed locally, and the resulting text is pasted at the current cursor position.
3. **Given** audio recording is active, **When** the user speaks clearly for 30 seconds, **Then** the full duration is captured without clipping or buffer loss.
4. **Given** transcription has completed, **When** the text is pasted, **Then** the visual indicator returns to idle state and the app is ready for the next dictation.

---

### User Story 2 - Recording Feedback (Priority: P2)

The user needs clear visual feedback about the current state of the
app — whether it is idle, recording, or processing transcription.
The menu bar icon changes to reflect each state so the user always
knows what is happening without switching context from their current
work.

**Why this priority**: Without state feedback, users cannot tell
whether their hotkey press registered or whether recording is active,
leading to confusion and lost dictation.

**Independent Test**: Can be tested by observing the menu bar icon
through each state transition (idle → recording → processing → idle)
and verifying each state is visually distinct.

**Acceptance Scenarios**:

1. **Given** the app is running and idle, **When** the user looks at the menu bar, **Then** they see an idle indicator (distinct from recording).
2. **Given** recording is active, **When** the user looks at the menu bar, **Then** they see a recording indicator that is clearly different from the idle state.
3. **Given** recording has stopped and transcription is in progress, **When** the user looks at the menu bar, **Then** they see a processing indicator.
4. **Given** transcription is complete and text has been pasted, **When** the process finishes, **Then** the indicator returns to idle within 1 second.

---

### User Story 3 - Error Recovery (Priority: P3)

The user attempts to dictate but something goes wrong — the
microphone is unavailable, the recording is too short to transcribe,
or transcription fails. The app communicates the problem clearly
and returns to a usable state without requiring a restart.

**Why this priority**: Errors in a background app are especially
frustrating because the user may not notice them immediately.
Graceful recovery ensures the app remains trustworthy.

**Independent Test**: Can be tested by simulating error conditions
(disconnecting the microphone, recording silence, recording for
less than 0.5 seconds) and verifying the app displays an error
notification and returns to idle.

**Acceptance Scenarios**:

1. **Given** no microphone is available or accessible, **When** the user presses Option+Space, **Then** the app displays a notification explaining the microphone issue and remains in idle state.
2. **Given** recording is active, **When** the user stops recording after less than 0.5 seconds, **Then** the app discards the recording, shows a brief notification ("Recording too short"), and returns to idle.
3. **Given** transcription fails for any reason, **When** the error occurs, **Then** the app displays a notification with the error summary and returns to idle state ready for the next attempt.

---

### Edge Cases

- What happens when the user presses the hotkey while transcription from a previous recording is still in progress? The new hotkey press MUST be ignored until the current transcription completes and pastes.
- What happens when the active application does not accept text input (e.g., Finder with no text field focused)? The transcribed text MUST still be placed on the system clipboard so the user can paste manually.
- What happens when the user records silence (no speech detected)? The app MUST display a "No speech detected" notification and return to idle without pasting empty text.
- What happens when the system microphone changes while recording is active? The recording MUST continue using the originally selected input device until the session ends.
- What happens when the app loses microphone permission at runtime? The app MUST detect the permission loss, stop recording if active, and prompt the user to re-grant permission.
- What happens when the user records for longer than 5 minutes? The system MUST auto-stop recording, notify the user, and proceed with transcription of what was captured.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register a global hotkey (default: Option+Space) that activates regardless of which application is in the foreground.
- **FR-002**: System MUST capture audio from the system's currently configured default input device when recording begins.
- **FR-003**: System MUST provide three visually distinct menu bar states: idle, recording, and processing.
- **FR-004**: System MUST play a subtle, distinct audio cue when recording starts and a different audio cue when recording stops. Audio cues MUST be short (under 0.5 seconds) and non-intrusive.
- **FR-005**: System MUST transcribe captured audio using a locally-running speech-to-text model with no network requests.
- **FR-006**: System MUST apply light cleanup to transcription output: automatic punctuation, sentence capitalization, and removal of filler words (e.g., "um", "uh", "like" when used as fillers). The original spoken meaning MUST be preserved — no rephrasing or grammar correction.
- **FR-007**: System MUST paste transcribed text at the current cursor position in the active application upon transcription completion.
- **FR-008**: System MUST fall back to placing transcribed text on the system clipboard when the active application does not accept pasted input.
- **FR-009**: System MUST discard recordings shorter than 0.5 seconds and notify the user.
- **FR-010**: System MUST automatically stop recording after 5 minutes of continuous capture and notify the user that the maximum duration was reached. Transcription of the captured audio MUST proceed normally.
- **FR-011**: System MUST display user-facing notifications for all error conditions (microphone unavailable, transcription failure, no speech detected).
- **FR-012**: System MUST return to idle state after every completed or failed dictation cycle, ready for the next activation.
- **FR-013**: System MUST NOT send any audio data, transcription results, or telemetry over the network.
- **FR-014**: System MUST request and verify microphone access permission before first use.

### Key Entities

- **Dictation Session**: Represents a single record-transcribe-paste cycle. Attributes: start time, end time, audio duration, transcription result (text or error), final state (completed, discarded, failed).
- **App State**: The current operational mode of the application. One of: idle, recording, processing. Transitions are triggered by hotkey presses and transcription completion/failure events.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete a full dictation cycle (press hotkey, speak, press hotkey, see text appear) in under 5 seconds for a 3-second utterance.
- **SC-002**: Transcription accuracy reaches at least 90% word accuracy for clear English speech in a quiet environment.
- **SC-003**: The app consumes less than 50 MB of memory when idle (not recording or transcribing).
- **SC-004**: 95% of dictation attempts by a new user succeed on the first try without consulting documentation.
- **SC-005**: All error conditions result in a user-visible notification and automatic return to idle state within 2 seconds.
- **SC-006**: The app remains responsive to hotkey input within 200 milliseconds of the key press.

## Clarifications

### Session 2026-03-28

- Q: What is the maximum recording duration before auto-stop? → A: 5 minutes, auto-stop with user notification.
- Q: What level of text cleanup should be applied to transcription output? → A: Light cleanup — add punctuation, capitalize sentences, trim filler words (um, uh, etc.).
- Q: Should the app play audio feedback on state transitions? → A: Yes, subtle sound on both recording start and stop (similar to macOS screenshot sound).

## Assumptions

- Users are on macOS 14 (Sonoma) or later with a functioning microphone.
- The user has granted microphone access permission to the app.
- A local speech-to-text model is bundled with or downloaded by the app before first dictation use (model management is out of scope for this feature).
- Dictation language is English only for the initial implementation.
- The hotkey combination (Option+Space) does not conflict with the user's existing macOS shortcuts (Spotlight uses Cmd+Space by default); if it does, the user resolves the conflict via system preferences.
- Audio quality is sufficient for transcription (built-in or external microphone in a reasonably quiet environment).
- The paste mechanism targets the frontmost application's focused text field; applications that intercept or block paste events may not receive the text.
