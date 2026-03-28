# Implementation Plan: Status Indicator GUI

**Branch**: `002-status-indicator-gui` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-status-indicator-gui/spec.md`

## Summary

Add a floating status overlay at the bottom center of the screen that visually communicates the app's current state: model loading (spinner), recording (pulsing red dot), transcribing (spinner), and error. The overlay is a non-activating, click-through NSPanel that appears above fullscreen apps only during recording and transcribing. It tracks the display containing the focused window. The existing AppState enum is extended with a `.loading` case to explicitly model the startup phase.

## Technical Context

**Language/Version**: Swift 6.2 with strict concurrency checking
**Primary Dependencies**: AppKit (NSPanel, Core Animation), WhisperKit (existing)
**Storage**: N/A
**Testing**: XCTest
**Target Platform**: macOS 26+, Apple Silicon and Intel
**Project Type**: Desktop app (LSUIElement menu bar utility)
**Performance Goals**: 60 fps animations, zero main-thread blocking during state transitions
**Constraints**: <50 MB idle memory (existing), indicator must not steal focus or appear in Cmd+Tab
**Scale/Scope**: Single user, single overlay window

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Privacy-First Local Processing | **Pass** | No network access. Indicator is purely local UI. |
| II. Type Safety & Correctness | **Pass** | IndicatorState is a typed enum. No force-unwraps. State transitions validated at compile time. |
| III. Test-First Development | **Pass** | AppState transition tests will be written first. Overlay behavior testable via state-driven updates. |
| IV. Performance-Conscious Design | **Pass** | Core Animation handles rendering on GPU. Indicator updates dispatched to main thread without blocking audio. Minimal memory overhead (single small window). |
| V. Simplicity & YAGNI | **Pass** | Single overlay window, no configuration UI, no plugin system. Indicator state derived from existing AppState — no parallel state management. |

**Platform constraints check**:

- AppKit for overlay: **Pass** (NSPanel + NSView + Core Animation)
- SwiftUI not used: **Pass**
- LSUIElement preserved: **Pass** (NSPanel with utility style doesn't affect Dock/Cmd+Tab)

**Post-Phase 1 re-check**: All gates still pass. No violations introduced during design.

## Project Structure

### Documentation (this feature)

```text
specs/002-status-indicator-gui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Wisp/
├── App/
│   └── AppDelegate.swift          # Modified: start in .loading, wire indicator
├── Models/
│   └── AppState.swift             # Modified: add .loading case + transitions
├── UI/
│   ├── MenuBarController.swift    # Modified: add .loading icon
│   ├── StatusOverlayWindow.swift  # New: NSPanel subclass for floating overlay
│   └── StatusIndicatorView.swift  # New: NSView with state-driven content
├── Services/
│   └── (unchanged)
└── Resources/
    └── (unchanged)

WispTests/
├── AppStateTests.swift            # Modified: add .loading transition tests
├── StatusOverlayWindowTests.swift # New: window level + positioning tests
└── StatusIndicatorViewTests.swift # New: state-driven content tests
```

**Structure Decision**: Follows existing single-project layout. New UI files go in `Wisp/UI/` alongside `MenuBarController.swift`. No new directories needed.

## Complexity Tracking

No constitution violations. Table not applicable.
