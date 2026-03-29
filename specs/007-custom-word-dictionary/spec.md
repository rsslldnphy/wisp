# Feature Specification: Custom Word Dictionary for Transcription Accuracy

**Feature Branch**: `007-custom-word-dictionary`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "if a user edits a word in the transcribed text, it should be added to a dictionary of commonly mistranscribed words that are appended to the prompt to help future transcriptions be more accurate. the user should be able to view edit add and delete words in the dictionary from the settings panel"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Dictionary Learning from Edits (Priority: P1)

When a user corrects a word in transcribed text (e.g., changes "wisk" to "whisk"), the app silently captures that correction and adds the corrected word to the personal dictionary. On the next transcription, the dictionary words are included in the transcription prompt so the speech model has better context, reducing repeat mistakes.

**Why this priority**: This is the core feedback loop — the dictionary is only valuable if it grows organically from real mistakes. Without this, the feature has no automatic value.

**Independent Test**: Can be tested by making a correction in a transcription, then starting a new transcription of the same phrase and verifying the correction appears naturally.

**Acceptance Scenarios**:

1. **Given** a transcription result is displayed, **When** the user edits a word in the text, **Then** the edited (corrected) word is automatically saved to the dictionary
2. **Given** the dictionary contains a corrected word, **When** a new transcription starts, **Then** the dictionary words are included in the transcription prompt
3. **Given** a word already exists in the dictionary, **When** the user edits to the same word again, **Then** no duplicate entry is created

---

### User Story 2 - View and Manage Dictionary in Settings (Priority: P2)

The user can open the settings panel and navigate to a dictionary section where all saved words are listed. They can add new words directly, edit existing entries, or remove words that are no longer relevant.

**Why this priority**: Users need to correct mistakes in the dictionary itself — if a wrong word gets added, or they want to seed the dictionary with known problem words upfront.

**Independent Test**: Can be tested entirely within the settings panel without performing any dictation — add, edit, and delete words and confirm the list updates correctly.

**Acceptance Scenarios**:

1. **Given** the settings panel is open, **When** the user navigates to the Dictionary section, **Then** a list of all saved words is displayed
2. **Given** the dictionary list is visible, **When** the user clicks "Add Word" and enters a word, **Then** the word is saved and appears in the list
3. **Given** the dictionary list is visible, **When** the user selects a word and edits it, **Then** the word is updated in place
4. **Given** the dictionary list is visible, **When** the user deletes a word and confirms, **Then** the word is removed from the list and no longer used in transcription prompts
5. **Given** the dictionary is empty, **When** the user views the Dictionary section, **Then** a helpful empty-state message is shown

---

### User Story 3 - Dictionary Persists Across App Restarts (Priority: P3)

The user's dictionary is saved persistently so that words are not lost when the app is closed and reopened.

**Why this priority**: Persistence is table-stakes for the feature to be useful, but it is a distinct concern from the capture and management flows.

**Independent Test**: Add a word, quit the app, reopen it, navigate to settings, and verify the word is still present.

**Acceptance Scenarios**:

1. **Given** words have been added to the dictionary, **When** the app is quit and relaunched, **Then** all dictionary words are still present
2. **Given** a word was deleted from the dictionary, **When** the app is quit and relaunched, **Then** the deleted word does not reappear

---

### Edge Cases

- What happens when the user edits a word to a blank or whitespace-only string?
- How does the system handle very long words or non-alphabetic characters (numbers, symbols)?
- What if the same word is added with different capitalisation (e.g., "Wisp" vs "wisp")?
- What if the user edits punctuation or whitespace rather than a recognisable word?
- What happens when the dictionary grows large enough that including all words would make the prompt unwieldy?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST capture the corrected word whenever a user edits a word in a displayed transcription result
- **FR-002**: System MUST store captured corrections in a persistent personal dictionary
- **FR-003**: System MUST deduplicate dictionary entries (case-insensitive comparison; store as entered by user)
- **FR-004**: System MUST include dictionary words in the transcription prompt on every new transcription when the dictionary is non-empty
- **FR-005**: Settings panel MUST include a dedicated Dictionary section listing all saved words
- **FR-006**: Users MUST be able to add new words manually from the Dictionary settings section
- **FR-007**: Users MUST be able to edit existing dictionary words from the Dictionary settings section
- **FR-008**: Users MUST be able to delete individual words from the Dictionary settings section
- **FR-009**: System MUST persist the dictionary across app restarts
- **FR-010**: System MUST show an empty-state message in the Dictionary section when no words have been saved
- **FR-011**: System MUST ignore edits that result in blank or whitespace-only text (not add them to the dictionary)

### Key Entities

- **Dictionary Entry**: A single corrected word. Key attribute: the word text. Optionally: date first added.
- **Dictionary**: The full collection of dictionary entries for the user. Consulted at transcription time to enrich the prompt.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After correcting a word in a transcription, that word appears in the dictionary settings list without any additional user action
- **SC-002**: A word that has been added to the dictionary is reflected in the transcription prompt for 100% of subsequent transcription sessions
- **SC-003**: Users can add, edit, and delete dictionary entries within the settings panel in under 30 seconds per operation
- **SC-004**: The dictionary is fully available within 2 seconds of the app launching, with no perceptible delay when opening the settings panel
- **SC-005**: The same phrase that was previously mistranscribed is transcribed correctly after the corrected word has been added to the dictionary

## Assumptions

- The transcription text is editable after a dictation session completes (existing behaviour from the transcription log feature)
- The system can detect which individual word was changed within an edit (before vs after comparison)
- The dictionary stores the corrected (intended) word only — not the original mistranscription — since the goal is to hint the model toward the correct form
- Dictionary words are appended to the existing transcription prompt as a natural-language hint (e.g., "Use these spellings when relevant: whisk, SwiftUI, Rosoll")
- There is no cloud sync requirement; the dictionary is local to the device only
- There is no import/export requirement for v1
- The dictionary is shared across all transcription sessions (not per-microphone or per-context)
