# Implementation Plan: Core Dictation Flow

**Branch**: `001-core-dictation-flow` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-core-dictation-flow/spec.md`

## Summary

Implement the core dictation flow for Wisp: a macOS menu bar app that
records audio on a global hotkey press (Option+Space), transcribes it
locally using WhisperKit (Whisper Small model via Core ML), applies
light text cleanup, and pastes the result at the cursor position.
The app runs as an LSUIElement (background-only) with three visual
states (idle, recording, processing) and audio cues on transitions.

## Technical Context

**Language/Version**: Swift 5.9+ with strict concurrency checking
**Primary Dependencies**: WhisperKit (Argmax), KeyboardShortcuts (Sindre Sorhus), AppKit
**Storage**: N/A (no persistent storage; ephemeral in-memory session data only)
**Testing**: XCTest (unit + integration with fixture audio files)
**Target Platform**: macOS 14+ (Sonoma), Apple Silicon and Intel
**Project Type**: Desktop app (menu bar utility)
**Performance Goals**: Transcription under 2x real-time on M1; <200ms hotkey response; <50MB idle memory
**Constraints**: Offline-only (no network); <50MB idle RAM; 5-minute max recording (~9.6 MB audio buffer)
**Scale/Scope**: Single-user desktop app; single active session at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
| --- | --- | --- |
| I. Privacy-First Local Processing | PASS | WhisperKit runs on-device via Core ML/Neural Engine. FR-013 prohibits network requests. No telemetry. |
| II. Type Safety & Correctness | PASS | Swift with strict concurrency. All entities use enums with associated values (no stringly-typed state). No force-unwraps in design. |
| III. Test-First Development | PASS | XCTest with mock audio buffers for unit tests. Integration tests use fixture .wav files for the full pipeline. TDD workflow enforced. |
| IV. Performance-Conscious Design | PASS | Audio capture on dedicated thread via AVAudioEngine. WhisperKit Small achieves ~0.3x RTF. Idle memory target <50MB (model unloaded). |
| V. Simplicity & YAGNI | PASS | No plugin system, no cloud sync, no settings beyond hotkey/mic/model. Single-purpose components with clear responsibilities. |

**Post-design re-check**: All gates still pass. No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-core-dictation-flow/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Wisp/
├── App/
│   ├── WispApp.swift            # App entry point (LSUIElement)
│   └── AppDelegate.swift        # Menu bar setup, permission requests
├── Models/
│   ├── AppState.swift           # State machine (idle/recording/processing)
│   ├── DictationSession.swift   # Session lifecycle
│   └── TranscriptionResult.swift # Result enum (completed/discarded/failed)
├── Services/
│   ├── AudioCaptureService.swift    # AVAudioEngine recording
│   ├── TranscriptionService.swift   # WhisperKit integration
│   ├── TextCleanupService.swift     # Filler word removal, formatting
│   ├── PasteService.swift           # NSPasteboard + CGEvent paste
│   └── HotkeyService.swift         # KeyboardShortcuts wrapper
├── UI/
│   ├── MenuBarController.swift      # NSStatusItem, icon state
│   └── Assets.xcassets/             # Menu bar icons (idle/recording/processing)
└── Resources/
    ├── Sounds/
    │   ├── record-start.aiff       # Start recording cue
    │   └── record-stop.aiff        # Stop recording cue
    └── Info.plist                   # LSUIElement=YES, permissions

WispTests/
├── Unit/
│   ├── AppStateTests.swift          # State machine transitions
│   ├── DictationSessionTests.swift  # Session lifecycle
│   ├── TextCleanupServiceTests.swift # Filler word removal
│   └── AudioCaptureServiceTests.swift # Mock buffer tests
├── Integration/
│   ├── TranscriptionPipelineTests.swift # Fixture audio → text
│   └── DictationFlowTests.swift         # Full cycle mock
└── Fixtures/
    ├── hello-world.wav              # Known phrase for accuracy tests
    ├── silence.wav                  # No-speech detection test
    └── short-clip.wav               # <0.5s discard test
```

**Structure Decision**: Single Xcode project with standard
App/Models/Services/UI grouping. No frameworks, packages, or
multi-target setup — per Constitution V (Simplicity & YAGNI),
the simplest structure that works for a single-purpose menu bar app.

## Complexity Tracking

> No violations detected. All design decisions align with constitution principles.
