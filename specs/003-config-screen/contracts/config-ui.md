# Contract: Configuration UI

**Type**: UI layout and validation behaviour contract
**Branch**: `003-config-screen` | **Date**: 2026-03-28

## Window

- Opens as a standard titled, closeable `NSWindow` (not a sheet, not a popover)
- Single persistent instance: calling "open" while already open brings the window to front rather than creating a second instance
- Minimum size: 480 × 360 pt
- Title bar text: "Wisp Preferences"
- Entry point: "Preferences…" `NSMenuItem` in the existing status bar menu, above "Quit Wisp"
- Keyboard: Escape key dismisses without saving (same as clicking the window close button)

## Sections

The panel contains three sections rendered in order:

### 1. Keyboard Shortcut

- Label: "Recording Shortcut"
- Control: `KeyboardShortcuts.Recorder("Toggle Dictation", name: .toggleDictation)`
- The recorder shows the current shortcut and enters capture mode on click
- System-reserved combination: recorder displays inline error (library-managed); previous value is preserved
- Cleared shortcut (empty field): save is blocked with an inline error — "A shortcut is required"
- Changes take effect immediately (library writes to UserDefaults and re-registers the global hotkey on commit)
- No explicit Save button needed for this field; the library commits on recorder dismiss

### 2. Microphone

- Label: "Input Microphone"
- Control: `Picker` (dropdown) listing all `MicrophoneDevice.displayName` values, keyed by `uid`
- When `MicrophoneList.devices` is empty: picker is replaced by an inline message "No microphones detected" and the picker/save for this section is disabled
- Device list refreshes automatically when devices are connected or disconnected (no manual refresh button)
- Currently selected device is pre-selected on panel open; falls back to the system default label if `selectedMicrophoneUID` is nil or the stored device is no longer connected
- Selection is written to `PreferencesStore` immediately on picker change (no separate Save needed)

### 3. Transcription Cleanup Prompt

- Label: "Cleanup Prompt"
- Control: multi-line `TextEditor` (min height 120 pt)
- Footer: "Reset to Default" button (link style) below the editor
- **Empty prompt validation**: if the text field is empty or whitespace-only when focus leaves the editor, an inline error appears — "Prompt cannot be empty. Enter text or reset to default." The previous valid value is preserved in `PreferencesStore`; the editor displays the error state until the user corrects it.
- "Reset to Default" restores `PreferencesStore.defaultCleanupPrompt` and clears any validation error
- Changes are written to `PreferencesStore` on focus loss from the editor (not character-by-character)

## Validation Summary

| Field | Empty/invalid action | User-visible message |
| ----- | -------------------- | -------------------- |
| Shortcut (cleared) | Block; preserve previous | "A shortcut is required" |
| Shortcut (system-reserved) | Block; preserve previous | Library-provided message |
| Cleanup prompt (blank) | Block; preserve previous | "Prompt cannot be empty. Enter text or reset to default." |
| Microphone (none connected) | Disable picker | "No microphones detected" |

## Live Effect Requirement

All saved changes MUST be observed by the relevant service for the next dictation session without restarting the app:

- Hotkey change: active within the same app session (library re-registers immediately)
- Microphone change: applied at the start of the next `AudioCaptureService.startRecording()` call
- Prompt change: applied at the start of the next `TextCleanupService.clean(_:)` call
