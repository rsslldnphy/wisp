# Feature Specification: Polish and Cleanup

**Feature Branch**: `006-polish-and-cleanup`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "couple of issues to clean up before this is done. one, can we make the logo a circular ghost that looks a bit like (but is legally distinct from) wisp from animal crossing? second, sometimes the transcript includes the initial 'beep' - is there a timing issue? third, can we add a 'launch wisp on startup' option to the dropdown menu? then i think the project is in a good shape"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Custom Ghost Logo (Priority: P1)

The app's menu bar icon should display a friendly, circular ghost character that gives Wisp a distinctive identity. The ghost should evoke the whimsical, translucent spirit aesthetic without reproducing any copyrighted or trademarked artwork — it must be clearly original.

**Why this priority**: The app icon is the most visible element of the product; it sets the tone and brand identity. Getting a distinctive look matters before the project is considered done.

**Independent Test**: Can be fully tested by launching the app and inspecting the menu bar icon — it either shows an original circular ghost or it does not.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** the user looks at the menu bar, **Then** the icon shows a circular ghost shape that is visually distinct from any Nintendo-owned artwork.
2. **Given** the ghost icon is displayed, **When** inspected at normal menu bar size, **Then** the ghost is clearly recognisable as a ghost (rounded head, wispy base or similar) and looks polished at small sizes.
3. **Given** macOS dark mode and light mode, **When** the icon is shown in either mode, **Then** it remains legible and visually appealing in both contexts.

---

### User Story 2 - Fix Beep Captured in Transcript (Priority: P2)

When a user triggers dictation, the app plays a start beep. Occasionally the beep sound itself is picked up by the microphone and transcribed as noise or garbled text at the beginning of the transcript. The recording should not begin until the beep has finished playing.

**Why this priority**: Transcription accuracy is the core value of the product. Artefacts from the app itself appearing in the transcript are a quality defect that undermines user trust.

**Independent Test**: Can be fully tested by triggering dictation and inspecting the resulting transcript — if the beep is never transcribed, the fix works.

**Acceptance Scenarios**:

1. **Given** the user triggers dictation, **When** the start beep plays, **Then** the microphone capture begins only after the beep has fully played, so the beep is never captured.
2. **Given** the user triggers dictation multiple times in succession, **When** each session starts, **Then** none of the transcripts contain audio artefacts from the start beep.
3. **Given** the user triggers dictation and speaks immediately after the beep, **When** the transcript is produced, **Then** all spoken words are captured and no beep noise appears at the start.

---

### User Story 3 - Launch on Startup Option (Priority: P3)

The app's menu should include a toggle to control whether Wisp launches automatically when the user logs in to their Mac. This removes the need to manually start the app after every reboot.

**Why this priority**: This is a quality-of-life convenience feature expected by mature menu bar apps. Lower priority because the app functions correctly without it.

**Independent Test**: Can be fully tested by enabling the option, restarting the Mac, and confirming Wisp is running; then disabling it, restarting again, and confirming it does not start automatically.

**Acceptance Scenarios**:

1. **Given** the dropdown menu is open, **When** the user views the menu, **Then** a "Launch Wisp on Startup" toggle item is present, showing its current state (enabled/disabled).
2. **Given** "Launch Wisp on Startup" is disabled, **When** the user selects it, **Then** it becomes enabled and Wisp will launch automatically after the next login.
3. **Given** "Launch Wisp on Startup" is enabled, **When** the user selects it again, **Then** it becomes disabled and Wisp will not launch automatically after the next login.
4. **Given** the startup preference has been set, **When** the app is quit and relaunched, **Then** the toggle reflects the previously saved state.

---

### Edge Cases

- What happens if the ghost icon is viewed on a non-Retina display — does it look acceptable at 1x resolution?
- What if the beep delay pushes the recording start noticeably later — does it feel laggy to the user?
- What happens if the system denies permission to register a login item — is the user informed with a helpful message?
- What if the user enables startup launch on a managed Mac where login items are restricted by policy?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app icon displayed in the menu bar MUST be a custom, original circular ghost illustration that is visually distinct from any Nintendo-owned artwork.
- **FR-002**: The ghost icon MUST be legible and polished at standard macOS menu bar icon sizes.
- **FR-003**: The ghost icon MUST adapt appropriately to both macOS light mode and dark mode so it remains visible in both contexts.
- **FR-004**: Microphone recording MUST NOT begin until the start beep has completely finished playing, ensuring the beep cannot be captured in the audio input.
- **FR-005**: Transcripts MUST NOT contain audio artefacts from the app's own start beep under normal operating conditions.
- **FR-006**: The dropdown menu MUST include a "Launch Wisp on Startup" toggle item.
- **FR-007**: The "Launch Wisp on Startup" toggle MUST reflect the current state (on/off) each time the menu is opened.
- **FR-008**: Enabling "Launch Wisp on Startup" MUST register Wisp as a login item so it launches automatically after the user logs in.
- **FR-009**: Disabling "Launch Wisp on Startup" MUST remove Wisp from the login items so it no longer launches automatically.
- **FR-010**: The startup preference MUST persist across app restarts and system reboots.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 10 consecutive dictation sessions, zero transcripts contain audio artefacts attributable to the app's start beep.
- **SC-002**: The ghost icon is instantly recognisable as a ghost at menu bar icon size by all users shown it without prior context.
- **SC-003**: The ghost icon passes a legal distinctness review — no identifiable elements from Nintendo's Wisp character artwork are reproduced.
- **SC-004**: After enabling "Launch on Startup" and logging out and back in, Wisp is running without any manual intervention, 100% of the time.
- **SC-005**: After disabling "Launch on Startup" and logging out and back in, Wisp does not launch automatically, 100% of the time.
- **SC-006**: The startup preference toggle state is accurately reflected in the menu every time it is opened.

## Assumptions

- The existing menu bar icon is a placeholder or system symbol; replacing it with a custom asset is safe and expected.
- macOS login item registration is done through the standard system API available to sandboxed apps; no special entitlements beyond what is already in place are required.
- A short fixed delay between beep completion and recording start (up to 500ms) is acceptable and will not feel laggy to users.
- The ghost illustration will be created as a vector/template asset by the developer; commissioning external designers is out of scope for this specification.
- "Legally distinct" means the ghost does not reproduce specific protected elements of Nintendo's Wisp character (exact colour palette, ear shape, expression, overall composition) even if it shares the general concept of a round ghost, which is not protected.
