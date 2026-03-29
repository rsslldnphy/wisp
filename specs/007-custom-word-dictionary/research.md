# Research: Custom Word Dictionary

**Branch**: `007-custom-word-dictionary` | **Date**: 2026-03-29

## Decision Log

---

### D-001: WhisperKit Initial Prompt API

**Decision**: Use `DecodingOptions.initialPrompt: String?` to inject dictionary words into every transcription call.

**Rationale**: WhisperKit's decoder accepts an initial prompt string that biases the model toward specific vocabulary and spelling. This is exactly the mechanism designed for custom vocabulary hints. The prompt is passed as a prefix token sequence, so the model favours those spellings when transcribing ambiguous audio.

**Alternatives considered**:
- Injecting into the LLM cleanup prompt only — rejected because the cleanup step runs after Whisper has already committed to its transcription; it can correct but cannot improve the initial decode.
- Both WhisperKit prompt + cleanup prompt — accepted as a complementary addition: dictionary words are appended to the cleanup prompt too, so the LLM step can also apply them as a consistency check.

**Implementation note**: `TranscriptionService.transcribe(audioBuffer:)` will accept a `wordHints: [String]` parameter and construct `DecodingOptions(initialPrompt: "Common words: \(wordHints.joined(separator: ", "))")` before calling WhisperKit.

---

### D-002: Word Extraction Strategy from Inline Edits

**Decision**: Simple set-difference on whitespace-split tokens. Words present in the new text but absent (case-insensitive) from the old text are treated as corrections and added to the dictionary.

**Rationale**: The dictionary is intended for proper nouns, unusual spellings, and technical terms — exactly the words Whisper gets wrong because they are rare in training data. These words are almost always single-token replacements (e.g. "wisp" → "Wisp", "swiftui" → "SwiftUI"). A full LCS diff would add complexity with no practical benefit for this use case.

**Alternatives considered**:
- Full LCS (longest common subsequence) word diff — overkill for single-word corrections; adds non-trivial code with no benefit in practice.
- Character-level diff — too granular; would capture partial word fragments.
- ML-based semantic comparison — far too heavyweight for comparing two short strings.

**Edge-case handling**:
- Blank/whitespace-only result: ignored, not added to dictionary.
- Punctuation stripped from token before comparison (`trimmingCharacters(in: .punctuationCharacters)`).
- Duplicate detection: case-insensitive check against existing dictionary before insert.

---

### D-003: Dictionary Persistence Mechanism

**Decision**: UserDefaults with key `com.wisp.wordDictionary` storing `[String]`.

**Rationale**: The dictionary is a flat ordered list of strings, expected to contain tens to a few hundred entries at most. UserDefaults handles this comfortably (well under the practical ~1 MB limit). This follows the existing pattern in `PreferencesStore` and avoids introducing a second persistence mechanism for what is logically a preference.

**Alternatives considered**:
- JSON file at `~/Library/Application Support/Wisp/word-dictionary.json` — consistent with `TranscriptionLogStore` pattern, but adds file I/O management (atomic writes, directory creation) for a simple string array. Overcomplicated here.
- CoreData — wildly over-engineered for a list of strings.

**Integration**: `WordDictionaryStore` will be an `@Observable @MainActor final class`, mirroring `PreferencesStore`. It will be instantiated once in `AppDelegate` and passed to `PreferencesView` and `TranscriptionService` via dependency injection (same pattern as `PreferencesStore`).

---

### D-004: Inline Editing in LogView

**Decision**: Add a tap-to-edit mode to `LogEntryRow`. A single tap on a row activates an inline `TextEditor` replacing the read-only `Text`. Committing (pressing Return or clicking outside) saves the edit, triggers word extraction, and updates the `TranscriptionLogStore` entry.

**Rationale**: Editing must feel lightweight and inline — opening a modal sheet for a word correction would be disproportionate friction. The existing `LogEntryRow` already has a per-row interaction model (copy button), so extending it to support an edit mode is natural.

**Alternatives considered**:
- Edit button per row that opens a sheet with a text field — rejected, too much friction for a minor correction.
- Making the `Text` view directly editable — SwiftUI `.textSelection(.enabled)` does not support editing; a `TextEditor` is required.

**TranscriptionLogEntry change required**: `text` is currently `let`. It will become `var` to allow mutation. `TranscriptionLogStore` will gain an `update(id: UUID, text: String)` method that replaces the entry in-place and persists to disk.

---

### D-005: Settings Panel Dictionary Section

**Decision**: Add a new `Section` in `PreferencesView` titled "Transcription Dictionary" containing a `List` of words with an inline delete button per row, plus an "Add Word" button that presents a small inline text field.

**Rationale**: Consistent with the existing settings panel structure (grouped form sections). Does not require a new window or sheet — the section lives naturally alongside Microphone, Shortcut, and Cleanup Prompt.

**Alternatives considered**:
- Separate preferences tab/screen — overkill for a list of words.
- Sheet presented from menu bar — inconsistent with existing settings UX.

---

### D-006: Cleanup Prompt Augmentation

**Decision**: Append dictionary words to the `cleanupPrompt` at cleanup time (not stored), formatted as: `\nUse these exact spellings when they appear: [word1, word2, ...]`.

**Rationale**: The LLM cleanup step can apply dictionary words as a post-processing consistency check. Words that Whisper gets partially correct (e.g. "swift UI" → "SwiftUI") benefit from the LLM seeing the correct form. This is a read-time augmentation — it does not change the stored `cleanupPrompt`.

**Alternatives considered**:
- Store augmented prompt — rejected, would require stripping dictionary words on each update and create a confusing UX in the TextEditor.
- Skip cleanup-prompt augmentation — acceptable fallback if it causes prompt length issues, but the benefit outweighs the cost.
