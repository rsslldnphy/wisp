# Quickstart: Custom Word Dictionary

**Branch**: `007-custom-word-dictionary`

## Feature Overview

Wisp learns from your corrections. When you edit a word in a transcription result, the corrected word is saved to a personal dictionary. That dictionary is then injected into every future transcription session so Whisper knows your preferred spellings upfront.

## How It Works

1. **Correction capture**: After dictating, open the Transcription Log. Tap any entry to edit it inline. When you commit the edit, any new words (words not in the original) are extracted and added to your dictionary automatically.

2. **Prompt injection**: At the start of each transcription, `WordDictionaryStore` provides the word list to `TranscriptionService`, which formats it as an `initialPrompt` for WhisperKit. The cleanup LLM also receives the words as a spelling hint.

3. **Settings management**: Open Wisp Preferences → "Transcription Dictionary" section to view, add, edit, or delete dictionary entries at any time.

## Key Components

| Component | File | Role |
|-----------|------|------|
| `WordDictionaryStore` | `Wisp/Models/WordDictionaryStore.swift` | Observable store; CRUD + persistence |
| `WordDictionaryView` | `Wisp/UI/WordDictionaryView.swift` | SwiftUI list + add/edit/delete UI |
| `LogEntryRow` (modified) | `Wisp/UI/LogView.swift` | Tap-to-edit + word extraction trigger |
| `TranscriptionService` (modified) | `Wisp/Services/TranscriptionService.swift` | Accepts `wordHints` param for WhisperKit |
| `TextCleanupService` (modified) | `Wisp/Services/TextCleanupService.swift` | Appends dictionary words to cleanup prompt |
| `PreferencesView` (modified) | `Wisp/UI/PreferencesView.swift` | Hosts `WordDictionaryView` as a section |
| `AppDelegate` (modified) | `Wisp/App/AppDelegate.swift` | Instantiates and wires `WordDictionaryStore` |

## Running the Feature

1. Build and run the app (Cmd+R in Xcode).
2. Use the hotkey to dictate a phrase containing a word Whisper gets wrong.
3. Open the Transcription Log from the menu bar.
4. Click on the mistranscribed entry, correct the word, press Return.
5. Open Preferences → Transcription Dictionary — the corrected word should appear.
6. Dictate the same phrase again — Whisper should now use the correct spelling.

## Testing

Run `XCTest` suite — all tests must pass before merge:

```
Product > Test (Cmd+U) in Xcode
```

Key test files to add:
- `WispTests/WordDictionaryStoreTests.swift` — CRUD, deduplication, persistence
- `WispTests/WordExtractionTests.swift` — `extractNewWords(from:to:)` edge cases
- `WispTests/LogEntryEditTests.swift` — edit flow, word extraction trigger
