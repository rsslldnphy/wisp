# wisp Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-28

## Active Technologies
- Swift 6.2 with strict concurrency checking + AppKit (NSPanel, Core Animation), WhisperKit (existing) (002-status-indicator-gui)
- Swift 6.2 with strict concurrency checking enabled + WhisperKit (existing), KeyboardShortcuts 2.x (Sindre Sorhus — re-add to Package.swift), AVFoundation (existing), CoreAudio (system framework), Apple FoundationModels (existing), AppKit + SwiftUI (003-config-screen)
- UserDefaults — two explicit keys (`selectedMicrophoneUID`, `cleanupPrompt`); hotkey managed automatically by KeyboardShortcuts library (003-config-screen)

- Swift 5.9+ with strict concurrency checking + WhisperKit (Argmax), KeyboardShortcuts (Sindre Sorhus), AppKi (001-core-dictation-flow)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Swift 5.9+ with strict concurrency checking

## Code Style

Swift 5.9+ with strict concurrency checking: Follow standard conventions

## Recent Changes
- 003-config-screen: Added Swift 6.2 with strict concurrency checking enabled + WhisperKit (existing), KeyboardShortcuts 2.x (Sindre Sorhus — re-add to Package.swift), AVFoundation (existing), CoreAudio (system framework), Apple FoundationModels (existing), AppKit + SwiftUI
- 002-status-indicator-gui: Added Swift 6.2 with strict concurrency checking + AppKit (NSPanel, Core Animation), WhisperKit (existing)

- 001-core-dictation-flow: Added Swift 5.9+ with strict concurrency checking + WhisperKit (Argmax), KeyboardShortcuts (Sindre Sorhus), AppKi

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
