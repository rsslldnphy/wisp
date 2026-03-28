# Quickstart: Core Dictation Flow

**Date**: 2026-03-28
**Feature**: 001-core-dictation-flow

## Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 15+ with Swift 5.9+
- A microphone (built-in or external)

## Build & Run

1. Clone the repository and open the Xcode project:
   ```bash
   git clone <repo-url>
   cd wisp
   open Wisp.xcodeproj
   ```

2. Select the "Wisp" scheme and "My Mac" as the run destination.

3. Build and run (Cmd+R). The app launches as a menu bar icon —
   it will NOT appear in the Dock or Cmd+Tab switcher.

4. On first launch, grant the requested permissions:
   - **Microphone Access**: Required for audio capture
   - **Accessibility**: Required for pasting text into other apps

## Usage

1. **Start dictation**: Press **Option+Space** (default hotkey).
   You'll hear a short audio cue and see the menu bar icon change
   to indicate recording.

2. **Speak naturally**. Recording continues until you stop it or
   the 5-minute maximum is reached.

3. **Stop dictation**: Press **Option+Space** again. You'll hear
   a stop cue and the icon changes to a processing indicator.

4. **Text appears**: The transcribed text is automatically pasted
   at your cursor position in the active application. If no text
   field is focused, the text is placed on the clipboard.

## Verify It Works

1. Open TextEdit and create a new document.
2. Press Option+Space → speak "Hello world" → press Option+Space.
3. Verify "Hello world." appears in the document (with punctuation).
4. Check that the menu bar icon returned to idle state.

## Troubleshooting

| Problem                        | Solution                                    |
|--------------------------------|---------------------------------------------|
| Hotkey doesn't respond         | Check System Settings > Privacy & Security > Accessibility |
| "Microphone unavailable" error | Check System Settings > Privacy & Security > Microphone |
| Text goes to clipboard only    | Click into a text field before dictating     |
| Option+Space conflicts         | Change hotkey via the menu bar icon > Settings |
