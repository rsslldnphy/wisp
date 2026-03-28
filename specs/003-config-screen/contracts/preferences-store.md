# Contract: PreferencesStore

**Type**: Actor API contract (consumed by `AudioCaptureService`, `TextCleanupService`, `PreferencesView`)
**Branch**: `003-config-screen` | **Date**: 2026-03-28

## Overview

`PreferencesStore` is the single source of truth for all user configuration. It is an `actor` to satisfy Swift 6.2 strict concurrency requirements. All reads and writes are `async` and must be `await`-ed.

## Public Interface

```swift
actor PreferencesStore {

    // MARK: - Cleanup Prompt

    /// Current prompt string. Never empty.
    var cleanupPrompt: String { get }

    /// The built-in default prompt (constant).
    static var defaultCleanupPrompt: String { get }

    /// Persists `prompt`. Throws `PreferencesError.emptyPrompt` if `prompt` is blank.
    func setCleanupPrompt(_ prompt: String) throws

    /// Resets cleanupPrompt to `defaultCleanupPrompt`.
    func resetCleanupPrompt()

    // MARK: - Microphone

    /// UID of the selected audio input device. nil = system default.
    var selectedMicrophoneUID: String? { get }

    /// Persists `uid`. Pass nil to clear (use system default).
    func setMicrophoneUID(_ uid: String?)

    /// Equivalent to setMicrophoneUID(nil).
    func resetMicrophone()
}
```

## Error Types

```swift
enum PreferencesError: Error {
    case emptyPrompt  // Raised by setCleanupPrompt when prompt is blank/whitespace-only
}
```

## Behavioural Constraints

- `cleanupPrompt` MUST NOT return an empty string at any point. If `UserDefaults` contains an empty value (e.g., corrupted state), `PreferencesStore` MUST return `defaultCleanupPrompt` as a fallback.
- `selectedMicrophoneUID` returning `nil` is valid and means "use AVAudioEngine's default input device". Callers MUST handle nil gracefully.
- Writes are synchronous to `UserDefaults.standard` within the actor. No async I/O.
- The actor MUST be safe to read from `@MainActor` (UI) and from background task contexts (service initialisation).

## Consumers

| Consumer | Property read | When |
| -------- | ------------- | ---- |
| `TextCleanupService` | `cleanupPrompt` | At start of each cleanup call |
| `AudioCaptureService` | `selectedMicrophoneUID` | Before starting AVAudioEngine |
| `PreferencesView` | both | On panel open and on every committed edit |
| `AppDelegate` | `selectedMicrophoneUID` | On app launch to configure initial device |
