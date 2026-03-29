# Data Model: Custom Word Dictionary

**Branch**: `007-custom-word-dictionary` | **Date**: 2026-03-29

## Entities

---

### WordDictionaryStore

New `@MainActor @Observable final class`. Single source of truth for the word dictionary.

```
WordDictionaryStore
├── words: [String]                           // ordered list, insertion order preserved
├── init(defaults: UserDefaults)              // loads from UserDefaults on init
├── add(_ word: String)                       // trims, deduplicates (case-insensitive), persists
├── update(at index: Int, word: String)       // replaces word at index, persists
├── remove(at offsets: IndexSet)              // removes entries at offsets, persists
├── remove(_ word: String)                    // removes first case-insensitive match
└── contains(_ word: String) -> Bool          // case-insensitive lookup
```

**Persistence**: UserDefaults key `com.wisp.wordDictionary` → `[String]`.
**Deduplication**: Before inserting, check `words.contains(where: { $0.caseInsensitiveCompare(word) == .orderedSame })`.
**Validation**: Ignore blank/whitespace-only inputs. Strip leading/trailing whitespace before storing.

---

### TranscriptionLogEntry (modified)

Existing struct — `text` promoted from `let` to `var` to allow in-place edits.

```
TranscriptionLogEntry (existing, modified)
├── id: UUID                    // unchanged
├── var text: String            // WAS let — now mutable for inline editing
├── timestamp: Date             // unchanged
└── wasPasted: Bool             // unchanged
```

No schema migration needed: the JSON serialisation is identical. The `var` change is purely in-memory.

---

### TranscriptionLogStore (modified)

Existing class — gains one new method for updating an entry's text.

```
TranscriptionLogStore (existing, extended)
└── update(id: UUID, text: String)   // NEW: replace text on matching entry, persist
```

---

### Word Extraction (pure function, no new type)

A free function (or static method on `WordDictionaryStore`) handles word extraction from edits:

```
extractNewWords(from oldText: String, to newText: String) -> [String]
```

**Algorithm**:
1. Tokenise both strings by splitting on whitespace and newlines.
2. Build `oldWords = Set(tokens.map { stripped($0).lowercased() })` where `stripped` removes leading/trailing punctuation.
3. For each token in `newText` tokens: if `stripped(token).lowercased()` ∉ `oldWords` and `stripped(token)` is non-empty → include in result.
4. Deduplicate result (preserve first occurrence, case-insensitive).

**Returns**: Words from the new text that were not present in the old text, deduplicated.

---

## State Transitions

### Word Dictionary Lifecycle

```
[empty]
   │ user edits transcription / manually adds word
   ▼
[words: ["SwiftUI", "Rosoll", ...]]
   │ new transcription starts
   ▼
[words injected into WhisperKit initialPrompt + cleanup prompt]
   │ user deletes or edits word in settings
   ▼
[words updated, persisted, active on next transcription]
```

### LogEntryRow Edit Mode

```
[read mode]   ──tap──▶   [edit mode: TextEditor]
                              │ Return / focus loss
                              ▼
                        [word extraction]
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
            [new words added      [entry text updated
             to dictionary]        in LogStore]
                    └─────────┬──────────┘
                              ▼
                        [read mode]
```

---

## Persistence Summary

| Data             | Mechanism    | Key / Path                              | Format        |
|------------------|--------------|-----------------------------------------|---------------|
| Word dictionary  | UserDefaults | `com.wisp.wordDictionary`               | `[String]`    |
| Transcription log| JSON file    | `~/Library/.../transcription-log.json` | `[Entry]`     |
| Preferences      | UserDefaults | `com.wisp.*`                            | Various       |
