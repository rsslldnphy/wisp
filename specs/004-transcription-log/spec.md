# Feature Specification: Transcription Log

**Feature Branch**: `004-transcription-log`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "I want to add a new option to the menu. A "show log" option that shows the log of the last up to 500 messages transcribed by the app. Each one will have a copy button that you can click to copy it to the clipboard."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Transcription History (Priority: P1)

A user who has dictated several messages throughout the day wants to review what was transcribed. They open the menu bar app and select "Show Log" to see their recent transcriptions. The log displays the last up to 500 entries in reverse-chronological order (most recent first), so they can quickly find recent dictations.

**Why this priority**: This is the core feature — without a browsable log, nothing else in this feature has value.

**Independent Test**: Can be fully tested by performing a dictation, then opening the log and verifying the transcription appears in the list. Delivers value as a read-only history even without copy functionality.

**Acceptance Scenarios**:

1. **Given** the user has completed at least one dictation, **When** they click "Show Log" in the menu, **Then** a window opens listing their transcribed messages with the most recent at the top.
2. **Given** the user has never dictated anything, **When** they open the log, **Then** an empty state message is shown (e.g., "No transcriptions yet").
3. **Given** the user has completed more than 500 dictations, **When** they open the log, **Then** only the 500 most recent entries are shown.

---

### User Story 2 - Copy a Transcription from Log (Priority: P2)

A user sees a message they transcribed earlier in the log and wants to re-use it. They click the copy button next to that entry and the text is placed on their clipboard, ready to paste elsewhere.

**Why this priority**: The copy action is the key interaction that makes the log actionable; without it the log is read-only reference only.

**Independent Test**: Can be fully tested by opening the log and clicking the copy button on any entry, then pasting to verify the correct text is on the clipboard.

**Acceptance Scenarios**:

1. **Given** the log is open with at least one entry, **When** the user clicks the copy button next to an entry, **Then** that entry's full transcribed text is copied to the system clipboard.
2. **Given** the user copies an entry, **When** they paste into any application, **Then** the exact transcribed text appears.
3. **Given** the log is open, **When** the user copies a second entry after a first, **Then** only the second entry's text is on the clipboard.

---

### Edge Cases

- What happens when the log is open and a new dictation completes — does the log update live or only on next open?
- How does the system handle very long transcriptions displayed in the list?
- If persisted log data is corrupted or unreadable on startup, the app silently discards it and presents an empty log.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The menu bar app MUST display a "Show Log" menu item.
- **FR-002**: Selecting "Show Log" MUST open a window listing the last up to 500 transcriptions produced by the app.
- **FR-003**: Transcriptions in the log MUST be displayed in reverse-chronological order (most recent first).
- **FR-004**: Each log entry MUST display the transcribed text and the timestamp of when the transcription was completed (e.g., "Mar 28, 2:32 PM").
- **FR-005**: Each log entry MUST include a copy button that, when clicked, copies the entry's full text to the system clipboard.
- **FR-006**: The transcription log MUST persist across app restarts — history must survive closing and reopening the app.
- **FR-007**: When the log contains no entries, the window MUST display an appropriate empty-state message.
- **FR-008**: The log MUST cap stored and displayed entries at 500; entries beyond this limit are automatically dropped (oldest first).
- **FR-009**: If persisted log data is corrupt or unreadable on app startup, the app MUST silently discard it and present an empty log — no error is shown to the user.

### Key Entities

- **Transcription Entry**: Represents a single completed dictation event. Key attributes: transcribed text, timestamp of completion.
- **Transcription Log**: An ordered collection of up to 500 Transcription Entries, ordered by timestamp descending.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open the transcription log from the menu in under 1 second.
- **SC-002**: All transcriptions produced during the current app session appear in the log when it is opened.
- **SC-003**: Users can copy any log entry to the clipboard with a single click.
- **SC-004**: Transcription history persists across 100% of normal app restarts (non-crash shutdowns).
- **SC-005**: The log correctly limits display to the 500 most recent entries when history exceeds that count.

## Clarifications

### Session 2026-03-28

- Q: Should each log entry display its timestamp alongside the transcribed text? → A: Yes — show timestamp per entry (e.g., "Mar 28, 2:32 PM")
- Q: What should happen if persisted log data is corrupted or unreadable on startup? → A: Silently discard corrupted data and start with an empty log

## Assumptions

- The log shows transcriptions produced by this app only; it does not import or show text from other sources.
- Each log entry stores the transcribed text and a timestamp — no metadata about the source application is required for v1.
- The log window does not need to update in real-time while open; reflecting the state at open time is acceptable.
- There is no requirement to delete individual entries or clear the entire log in v1.
- The "Show Log" menu item appears in the existing menu bar app menu alongside other existing options.
- Log data is stored locally on the user's device and is not synced or shared.
