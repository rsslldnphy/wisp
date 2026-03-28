# Feature Specification: Configuration Screen

**Feature Branch**: `003-config-screen`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "add a configuration screen that allows changing the keyboard shortcut used to start and stop recording, amending the prompt given to the llm that cleans up transcription, and switching microphone"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Change Recording Keyboard Shortcut (Priority: P1)

A user wants to reassign the keyboard shortcut that starts and stops dictation recording to a key combination that fits their workflow and doesn't conflict with other applications.

**Why this priority**: The keyboard shortcut is the primary interaction mechanism for the app. If the default conflicts with another app, the user cannot use Wisp effectively. This is the most likely and most impactful configuration need.

**Independent Test**: Can be fully tested by opening the configuration screen, recording a new shortcut, saving, and verifying that dictation starts and stops with the new shortcut.

**Acceptance Scenarios**:

1. **Given** the configuration screen is open, **When** the user clicks the shortcut capture field and presses a key combination, **Then** the new combination is displayed and saved as the active shortcut
2. **Given** a new shortcut has been saved, **When** the user presses that combination in any application, **Then** Wisp starts or stops recording
3. **Given** the user enters a shortcut that conflicts with a system shortcut, **When** they attempt to save, **Then** a conflict warning is shown and the previous shortcut is preserved

---

### User Story 2 - Switch Microphone Input (Priority: P2)

A user has multiple microphones connected (e.g., built-in mic, USB headset, external condenser) and wants to choose which one Wisp uses for dictation.

**Why this priority**: Users with external or higher-quality microphones need to direct input accordingly. Without this, transcription quality may be poor despite better hardware being available.

**Independent Test**: Can be fully tested by opening configuration, selecting a different microphone from the list, saving, and verifying that a recording captures audio from the chosen device.

**Acceptance Scenarios**:

1. **Given** the configuration screen is open, **When** the user opens the microphone selector, **Then** all currently connected audio input devices are listed with their display names
2. **Given** a microphone is selected and saved, **When** the user starts a dictation session, **Then** audio is captured from the selected device
3. **Given** the previously selected microphone has been disconnected, **When** the user opens the configuration screen, **Then** the missing device is indicated and a usable fallback is shown

---

### User Story 3 - Amend the Transcription Cleanup Prompt (Priority: P3)

A user wants to customise the instructions given to the language model that post-processes raw transcription output — for example, to enforce a writing style, remove filler words, or preserve domain-specific terminology.

**Why this priority**: The default prompt serves most users well; this is a power-user customisation. It delivers less immediate value than shortcut and microphone settings but is important for users with specialised output requirements.

**Independent Test**: Can be fully tested by opening configuration, editing the prompt, saving, completing a dictation session, and verifying the cleaned-up output reflects the new instructions.

**Acceptance Scenarios**:

1. **Given** the configuration screen is open, **When** the user views the cleanup prompt field, **Then** the current prompt text is displayed and editable
2. **Given** the user has modified the prompt and saved, **When** a dictation session completes, **Then** the LLM cleanup step uses the updated prompt
3. **Given** the user wants to revert their prompt changes, **When** they activate a "Reset to Default" action, **Then** the prompt is restored to the original default text

---

### Edge Cases

- When no microphone is connected, the device list shows an explanatory message (e.g., "No microphones detected") and saving the microphone setting is disabled until a device is connected
- Saving an empty cleanup prompt is blocked; an inline error instructs the user to enter a value or use "Reset to Default"
- Saving a cleared keyboard shortcut field is blocked; an inline error requires the user to enter a valid combination or revert to the previous value
- The microphone device list refreshes automatically when a device is connected or disconnected while the configuration screen is open

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST provide a configuration screen accessible from the menu bar or status indicator
- **FR-002**: The configuration screen MUST display the current keyboard shortcut for starting/stopping recording
- **FR-003**: Users MUST be able to record a new keyboard shortcut by pressing a combination into a dedicated capture field; saving a cleared (empty) shortcut field MUST be blocked with an inline error
- **FR-004**: The system MUST detect conflicts with macOS system-reserved shortcuts and warn the user before saving; conflicts with third-party applications are out of scope
- **FR-005**: The configuration screen MUST list all available audio input devices currently connected to the system; when no devices are connected, an explanatory message MUST be shown and saving the microphone setting MUST be disabled; the list MUST refresh automatically when devices are connected or disconnected while the screen is open
- **FR-006**: Users MUST be able to select any listed audio input device as the active recording microphone
- **FR-007**: The selected microphone MUST persist across app restarts
- **FR-008**: The configuration screen MUST display the current transcription cleanup prompt in an editable text area
- **FR-009**: Users MUST be able to edit the cleanup prompt and save the changes; saving an empty prompt MUST be blocked with an inline error directing the user to enter text or use "Reset to Default"
- **FR-010**: The system MUST provide a "Reset to Default" action that restores the original cleanup prompt
- **FR-011**: All configuration changes MUST take effect for subsequent dictation sessions without restarting the app
- **FR-012**: The configuration screen MUST be dismissible without saving, discarding any unsaved changes

### Key Entities

- **Keyboard Shortcut**: A user-defined key combination that triggers recording start/stop; has a current value and a system default value
- **Microphone**: An available audio input device with a display name and a system identifier; one device is designated as active
- **Cleanup Prompt**: A free-text instruction string passed to the LLM during transcription post-processing; has a current value and a default value

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open the configuration screen in 2 or fewer interactions from normal app usage
- **SC-002**: All three configuration areas (shortcut, microphone, cleanup prompt) can be changed and saved in a single visit to the configuration screen
- **SC-003**: 100% of currently connected audio input devices appear in the device list when the configuration screen is opened
- **SC-004**: The cleanup prompt field accepts at least 1000 characters to accommodate detailed instructions
- **SC-005**: All configuration values are correctly preserved and applied across at least 10 consecutive app restarts

## Clarifications

### Session 2026-03-28

- Q: What should happen when the user attempts to save an empty cleanup prompt? → A: Block saving; show an inline error telling the user to enter a value or use Reset to Default
- Q: What is the scope of keyboard shortcut conflict detection? → A: System-reserved macOS shortcuts only; third-party app conflicts are out of scope
- Q: What happens when no microphone is connected when the configuration screen is opened? → A: Show empty list with explanatory message; disable saving the microphone setting until a device is connected
- Q: What happens if the user clears the keyboard shortcut field entirely? → A: Block saving; show an inline error requiring a valid combination or revert to previous value
- Q: Should the microphone list refresh automatically when devices are connected/disconnected while the screen is open? → A: Yes, refresh automatically

## Assumptions

- The configuration screen is a modal or settings panel launched from the existing menu bar icon or status indicator; no separate window infrastructure is assumed to pre-exist
- Only one keyboard shortcut is in scope (the start/stop toggle); any other potential shortcuts are out of scope for this feature
- The LLM cleanup prompt is a single free-text field; structured prompt templating (variables, conditionals, multi-step prompts) is out of scope
- The app already sends a prompt to an LLM for transcription cleanup; this feature exposes that prompt for user editing but does not introduce the cleanup step itself
- Audio input device enumeration relies on system APIs already accessible within the app's existing microphone permissions
- "Switching microphone" refers to audio input device selection only; output/playback devices are out of scope
