# Implementation Plan: Custom Word Dictionary for Transcription Accuracy

**Branch**: `007-custom-word-dictionary` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-custom-word-dictionary/spec.md`

## Summary

When users correct words in transcribed text, the corrections are saved to a local personal dictionary that is injected as an `initialPrompt` into WhisperKit on every subsequent transcription. Users can manage the dictionary (view, add, edit, delete) in a new "Transcription Dictionary" section of the Preferences panel. All storage is local-only (UserDefaults). The feature requires: (1) adding inline editing to `LogEntryRow` with word-diff extraction, (2) a new `WordDictionaryStore`, and (3) threading the store through `TranscriptionService` and `TextCleanupService`.

## Technical Context

**Language/Version**: Swift 6.1+ with strict concurrency checking enabled
**Primary Dependencies**: WhisperKit (existing), FoundationModels (existing), AppKit + SwiftUI (existing), KeyboardShortcuts (existing)
**Storage**: UserDefaults (`com.wisp.wordDictionary` → `[String]`)
**Testing**: XCTest (existing)
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: macOS desktop app (background utility, LSUIElement)
**Performance Goals**: Dictionary lookup and prompt construction must add < 1 ms to transcription startup
**Constraints**: Offline-only, no cloud sync, no external APIs
**Scale/Scope**: Single user, expected dictionary size: 10–300 words

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Privacy-First Local Processing | ✅ PASS | Dictionary stored in UserDefaults; no data leaves device |
| II. Type Safety & Correctness | ✅ PASS | `WordDictionaryStore` uses explicit types; no force-unwraps; `TranscriptionLogEntry.text` promoted to `var` cleanly |
| III. Test-First Development | ✅ PASS | Tests for `WordDictionaryStore`, `extractNewWords`, and log-edit flow are part of the task plan |
| IV. Performance-Conscious Design | ✅ PASS | String array lookup and `joined(separator:)` add negligible overhead; no hot-path impact |
| V. Simplicity & YAGNI | ✅ PASS | No speculative features; word extraction uses simple set-difference (no LCS); UserDefaults (not a new file) |

**Post-design re-check**: Inline editing adds a small `@State isEditing: Bool` to `LogEntryRow` — single clear responsibility, no abstraction violations. Dictionary section in `PreferencesView` is a new `Section`, not a new screen. All constitution gates still pass.

## Project Structure

### Documentation (this feature)

```text
specs/007-custom-word-dictionary/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (repository root)

```text
Wisp/
├── App/
│   └── AppDelegate.swift            ← modified: instantiate + wire WordDictionaryStore
├── Models/
│   ├── WordDictionaryStore.swift    ← NEW
│   └── TranscriptionLogEntry.swift  ← modified: text let → var
│   └── TranscriptionLogStore.swift  ← modified: add update(id:text:) method
├── Services/
│   ├── TranscriptionService.swift   ← modified: accept wordHints param
│   └── TextCleanupService.swift     ← modified: augment prompt with dictionary words
└── UI/
    ├── WordDictionaryView.swift     ← NEW: SwiftUI list for managing dictionary
    ├── LogView.swift                ← modified: tap-to-edit LogEntryRow + word extraction
    └── PreferencesView.swift        ← modified: add Transcription Dictionary section

WispTests/
├── WordDictionaryStoreTests.swift   ← NEW
├── WordExtractionTests.swift        ← NEW
└── LogEntryEditTests.swift          ← NEW
```

**Structure Decision**: Single-project layout (existing). New files follow established `Models/` and `UI/` conventions. No new directories needed.

## Complexity Tracking

> No constitution violations — section not applicable.
