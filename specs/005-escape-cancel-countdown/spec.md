# Feature Specification: Escape Cancel Countdown with Progress Bar

**Feature Branch**: `005-escape-cancel-countdown`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "the last commit adds the functionality to handle escape to stop recording, still transcribe, but not paste. can you improve this feature by instead of switching to transcribing, it switches to showing a countdown of 3 seconds (with a progress bar) that says 'cancelling' and if escape is pressed again it goes back to transcribing, and will paste the result, but if escape is not pressed, the ui element disappears, the transcription continues and will be saved in the log, but won't be pasted"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escape Triggers Cancellation Countdown (Priority: P1)

When a user is recording dictation and presses Escape, instead of immediately switching to the transcribing state, the UI transitions to a "Cancelling" state that displays a 3-second animated countdown with a progress bar. During this window, the user can still reverse the decision.

**Why this priority**: This is the core behaviour change — replacing the immediate cancel with a reversible countdown. Everything else depends on this being in place.

**Independent Test**: Start a recording, press Escape, and verify the UI shows a countdown progress bar labelled "Cancelling" for approximately 3 seconds before disappearing.

**Acceptance Scenarios**:

1. **Given** the user is recording, **When** Escape is pressed, **Then** the recording stops and the UI transitions to a "Cancelling" state showing a progress bar that visually counts down from full to empty over 3 seconds.
2. **Given** the countdown is running, **When** it reaches 0 without further input, **Then** the UI element disappears, transcription continues silently in the background, and the result is saved to the transcription log but not pasted.
3. **Given** the countdown is running, **When** the user presses Escape again before it expires, **Then** the countdown is cancelled, the UI transitions back to a "Transcribing" state, and once complete the result is pasted as normal.

---

### User Story 2 - Silent Background Transcription and Log Save (Priority: P2)

When the countdown expires without user intervention, the audio that was recorded is still transcribed in the background. The transcription result is silently saved to the transcription log. No text is pasted into the active application.

**Why this priority**: Preserving the recorded content in the log (even when cancelled) is a significant data-safety improvement over discarding it entirely.

**Independent Test**: Press Escape during recording, let the countdown expire, then open the transcription log and confirm a new entry appears with the correct transcription text and an indicator that it was not pasted.

**Acceptance Scenarios**:

1. **Given** the countdown expired without a second Escape press, **When** transcription completes, **Then** the result appears in the transcription log with the content intact.
2. **Given** a cancelled transcription is saved, **Then** it is distinguishable in the log from normal (pasted) transcriptions (e.g., marked as "not pasted" or "cancelled").
3. **Given** transcription is running in the background after the UI disappears, **Then** no visual indicator is shown to the user and no paste event is triggered.

---

### User Story 3 - Second Escape Restores Paste Behaviour (Priority: P2)

If the user presses Escape a second time while the countdown is active, the cancellation is reversed. The transcription proceeds as if Escape had never been pressed — once complete, the result is pasted into the previously focused application.

**Why this priority**: This undo path is the primary safety net that makes the countdown valuable. Without it, the countdown has no user-facing benefit over the previous immediate-cancel behaviour.

**Independent Test**: Press Escape during recording, immediately press Escape again while countdown is visible, and verify the UI switches to "Transcribing" and the final result is pasted.

**Acceptance Scenarios**:

1. **Given** the "Cancelling" countdown is showing, **When** Escape is pressed a second time, **Then** the UI immediately transitions to the "Transcribing" state.
2. **Given** the user reversed the cancellation, **When** transcription completes, **Then** the result is pasted into the previously focused application exactly as in the normal recording flow.
3. **Given** the user reversed the cancellation, **Then** the transcription log entry is marked as a normal (pasted) transcription.

---

### Edge Cases

- What happens if the user presses Escape a third time during the "Transcribing" state (after reversing)?
- **Too-short recordings**: If Escape is pressed and the recording is < 0.5 s, the countdown is skipped entirely. The stop sound plays, no HUD is shown, and the audio is silently discarded — identical to today's too-short behavior.
- What if the application loses focus during the countdown — does the countdown still run to completion?
- **Transcription failure after cancel**: If the silent background transcription fails (error or no speech detected), the result is silently discarded — no log entry is created and no notification is shown.
- What if the user presses Escape more than twice in rapid succession while in "Cancelling" state?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When Escape is pressed during recording and the audio duration is ≥ 0.5 s, the system MUST stop audio capture and transition the UI to a "Cancelling" state instead of directly to a transcribing state. If the audio duration is < 0.5 s, the system MUST skip the countdown entirely, play the stop sound, and silently discard the audio (no HUD shown).
- **FR-002**: The "Cancelling" state MUST display a progress bar that visually animates from full to empty over exactly 3 seconds.
- **FR-003**: The "Cancelling" state MUST display the label "Cancelling" (or clear equivalent) so the user understands the countdown's purpose.
- **FR-004**: If Escape is pressed a second time while the countdown is active, the system MUST cancel the countdown and transition the UI to the "Transcribing" state with paste-on-completion behaviour restored.
- **FR-005**: If the countdown expires without a second Escape press, the UI element MUST disappear and transcription MUST proceed silently in the background.
- **FR-006**: After a countdown expiry, a successfully completed transcription MUST be saved to the transcription log. If transcription fails or produces no speech, the result MUST be silently discarded with no log entry and no notification.
- **FR-007**: After a countdown expiry, the completed transcription MUST NOT be pasted into any application.
- **FR-008**: Log entries resulting from a cancelled (not-pasted) transcription MUST be distinguishable from normal pasted entries.
- **FR-009**: After the second Escape restores normal flow, the completed transcription MUST be pasted into the application that was focused at the time recording started.

### Key Entities

- **CancelCountdown**: Represents the 3-second window between Escape press and final cancellation decision. Attributes: total duration (3 s), remaining time, resolved state (expired vs. reversed).
- **TranscriptionLogEntry**: Extended to include a flag indicating whether the transcription was pasted, distinguishing cancelled from normal entries.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After pressing Escape during recording, the "Cancelling" countdown appears within 100 ms.
- **SC-002**: The countdown progress bar completes its animation in 3 seconds (± 100 ms).
- **SC-003**: 100% of transcriptions from cancelled recordings are saved to the log with correct content.
- **SC-004**: 0% of cancelled transcriptions result in a paste event in any external application.
- **SC-005**: Pressing Escape a second time during the countdown restores paste behaviour in 100% of cases, with the UI transitioning to "Transcribing" within 100 ms of the second key press.
- **SC-006**: The normal recording → transcribing → paste flow is unaffected when Escape is not pressed (zero regressions on the happy path).

## Clarifications

### Session 2026-03-29

- Q: When Escape is pressed but the recording is too short (< 0.5 s), should the "Cancelling" countdown appear at all? → A: Skip countdown entirely — play stop sound, show no HUD, silently discard (identical to existing too-short behavior).
- Q: If transcription fails during silent background processing after countdown expiry, what should happen? → A: Silently discard — no log entry saved, no error notification shown.

## Assumptions

- The recorded audio buffer is retained in memory during the countdown so transcription can still proceed after the UI dismisses.
- The transcription log already exists and accepts new entries; this feature only adds a "not pasted" distinction to log entries.
- The 3-second countdown duration is fixed and not user-configurable in this iteration.
- A third (or subsequent) Escape press during the "Transcribing" state (after reversal) follows whatever behaviour the existing codebase already defines for that state.
- Focus tracking (knowing where to paste on reversal) is already handled by the existing paste mechanism and requires no changes.
