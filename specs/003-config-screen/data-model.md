# Data Model: Configuration Screen

**Branch**: `003-config-screen` | **Date**: 2026-03-28

## Entities

### PreferencesStore (actor)

Single source of truth for all user configuration. Backed by `UserDefaults.standard`.

| Property | Type | Default | Persistence Key |
| -------- | ---- | ------- | --------------- |
| `cleanupPrompt` | `String` | See default prompt below | `com.wisp.cleanupPrompt` |
| `selectedMicrophoneUID` | `String?` | `nil` (system default) | `com.wisp.selectedMicrophoneUID` |
| hotkey | managed by `KeyboardShortcuts` library | `Option+Space` | library-managed |

**Validation rules**:
- `cleanupPrompt` MUST NOT be empty. Writing an empty string is rejected; callers receive an error or the write is silently ignored and the previous value retained.
- `selectedMicrophoneUID` MAY be `nil` — means "use whatever AVAudioEngine resolves as the default input device".
- Hotkey is validated by the `KeyboardShortcuts.Recorder` view before write; system-reserved combinations are rejected.

**Default cleanup prompt** (verbatim from current `TextCleanupService.swift`):
```
You are a dictation cleanup assistant. Clean up the following transcribed speech. Rules:
- Remove filler words (um, uh, like when used as filler, you know, etc.)
- Fix punctuation and capitalization
- Preserve the original meaning exactly — do NOT rephrase or rewrite
- Do NOT add any commentary, just return the cleaned text
- If the input is already clean, return it unchanged
```

**Methods**:
- `setCleanupPrompt(_ prompt: String) throws` — writes to UserDefaults; throws `PreferencesError.emptyPrompt` if blank
- `resetCleanupPrompt()` — restores default prompt string
- `setMicrophoneUID(_ uid: String?)` — writes to UserDefaults; nil clears selection (system default)
- `resetMicrophone()` — writes nil (equivalent to `setMicrophoneUID(nil)`)

---

### MicrophoneDevice (struct, Sendable)

Represents a single audio input device as returned by CoreAudio enumeration.

| Property | Type | Notes |
| -------- | ---- | ----- |
| `uid` | `String` | Stable `kAudioDevicePropertyDeviceUID` from CoreAudio; used as persistence key |
| `displayName` | `String` | `kAudioDevicePropertyDeviceName` from CoreAudio; shown in picker |
| `isDefault` | `Bool` | `true` if this device is the current system default input |

**Validation rules**:
- `uid` and `displayName` are always non-empty (CoreAudio guarantees); no additional validation needed.
- `isDefault` is derived at enumeration time; not stored in UserDefaults.

**Identity**: Two `MicrophoneDevice` values with equal `uid` are considered the same physical device regardless of `displayName` or `isDefault`.

---

### MicrophoneList (actor)

Manages the live list of `MicrophoneDevice` values and CoreAudio property listener registration.

| Property | Type | Notes |
| -------- | ---- | ----- |
| `devices` | `[MicrophoneDevice]` | Current connected input devices; empty array if none |
| `selectedUID` | `String?` | Mirrors `PreferencesStore.selectedMicrophoneUID`; drives picker selection |

**State transitions**:

```
idle (devices: [...])
    │
    ├─ device connected ──→ devices list updated (hot-plug callback)
    ├─ device disconnected → devices list updated; if selectedUID was the removed device → selectedUID set to nil
    └─ user selects device → selectedUID written to PreferencesStore
```

**Empty state**: When `devices` is empty the config UI shows an explanatory message and the save action for microphone is disabled (FR-005).

---

## State: Configuration Panel

The preferences panel has the following local UI state (not persisted):

| State | Description |
| ----- | ----------- |
| `editing` | Panel is open; user may be editing any field |
| `promptValidationError` | Non-nil when user has cleared the prompt field and attempts to save |
| `shortcutConflictError` | Non-nil when `KeyboardShortcuts.Recorder` reports a system-reserved combination (library-managed) |
| `microphoneUnavailable` | True when `MicrophoneList.devices` is empty |

**Discard behaviour**: Dismissing the panel without saving (Escape / close button) reverts all in-flight edits. `PreferencesStore` is only written on explicit Save or per-field commit (TBD in tasks phase — either auto-save per field or explicit Save button; both are valid; tasks phase resolves the choice).

---

## Relationship Summary

```
AppDelegate
    └── PreferencesStore (actor, injected into services)
            ├── AudioCaptureService reads selectedMicrophoneUID
            └── TextCleanupService reads cleanupPrompt

PreferencesWindow (NSWindowController)
    └── PreferencesView (SwiftUI)
            ├── KeyboardShortcuts.Recorder  ← reads/writes hotkey (library-managed)
            ├── MicrophonePickerSection
            │       └── MicrophoneList (actor) ← reads/writes selectedMicrophoneUID via PreferencesStore
            └── PromptEditorSection
                    └── reads/writes cleanupPrompt via PreferencesStore
```
