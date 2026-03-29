# wisp Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-29

## Active Technologies
- Swift 6.2 with strict concurrency checking + AppKit (NSPanel, Core Animation), WhisperKit (existing) (002-status-indicator-gui)
- Swift 6.2 with strict concurrency checking enabled + WhisperKit (existing), KeyboardShortcuts 2.x (Sindre Sorhus — re-add to Package.swift), AVFoundation (existing), CoreAudio (system framework), Apple FoundationModels (existing), AppKit + SwiftUI (003-config-screen)
- UserDefaults — two explicit keys (`selectedMicrophoneUID`, `cleanupPrompt`); hotkey managed automatically by KeyboardShortcuts library (003-config-screen)
- Swift 6.1+ with strict concurrency checking enabled + AppKit (NSWindow, NSMenu), SwiftUI (List, Button), Foundation (Codable, JSONEncoder/Decoder, FileManager) (004-transcription-log)
- JSON file — `~/Library/Application Support/Wisp/transcription-log.json` (004-transcription-log)
- Swift 6.1+ with strict concurrency checking enabled + AppKit (NSPanel, Core Animation), WhisperKit (existing), AVFoundation (existing) (005-escape-cancel-countdown)
- JSON file at `~/Library/Application Support/Wisp/transcription-log.json` (existing) (005-escape-cancel-countdown)

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
- 005-escape-cancel-countdown: Added Swift 6.1+ with strict concurrency checking enabled + AppKit (NSPanel, Core Animation), WhisperKit (existing), AVFoundation (existing)
- 004-transcription-log: Added Swift 6.1+ with strict concurrency checking enabled + AppKit (NSWindow, NSMenu), SwiftUI (List, Button), Foundation (Codable, JSONEncoder/Decoder, FileManager)
- 003-config-screen: Added Swift 6.2 with strict concurrency checking enabled + WhisperKit (existing), KeyboardShortcuts 2.x (Sindre Sorhus — re-add to Package.swift), AVFoundation (existing), CoreAudio (system framework), Apple FoundationModels (existing), AppKit + SwiftUI


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
