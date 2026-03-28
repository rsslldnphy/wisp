# Research: Core Dictation Flow

**Date**: 2026-03-28
**Feature**: 001-core-dictation-flow

## Decision 1: Local Whisper Runtime

**Decision**: Use WhisperKit by Argmax with the Whisper Small model.

**Rationale**: WhisperKit is a Swift-native framework that leverages
Core ML and the Apple Neural Engine for hardware-accelerated inference.
It provides async/await APIs, integrates via Swift Package Manager,
and achieves ~0.3x real-time factor on Apple Silicon (well under the
2x RTF target). The Small model (244M parameters) balances accuracy
and speed for dictation use cases.

**Alternatives considered**:
- **whisper.cpp with Swift bindings (SwiftWhisper)**: Viable but
  requires C++ bridging and manual memory management. Better for
  cross-platform projects.
- **Manual Core ML conversion**: Maximum flexibility but requires
  Python tooling and conversion workflows. Unnecessary complexity
  when WhisperKit provides pre-converted models.

**Key details**:
- Model size on disk: ~466 MB (quantized)
- Runtime memory: ~852 MB during transcription
- Idle memory: model can be unloaded when not transcribing
- Whisper natively produces punctuation and capitalization — light
  cleanup (filler word removal) still needs post-processing
- Pre-converted Core ML models available from Argmax model hub

## Decision 2: Global Hotkey Registration

**Decision**: Use CGEventTap for hotkey capture, wrapped with the
KeyboardShortcuts library by Sindre Sorhus for user configuration
and persistence.

**Rationale**: CGEventTap is the modern standard for global hotkey
interception on macOS. It works reliably with LSUIElement background
apps and has a clear permission model (Input Monitoring). The
KeyboardShortcuts library provides SwiftUI-compatible configuration
UI, UserDefaults persistence, and system shortcut conflict detection.

**Alternatives considered**:
- **Carbon RegisterEventHotKey**: Deprecated; broken for Option-only
  modifiers on macOS 15+.
- **NSEvent.addGlobalMonitorForEvents**: Read-only (cannot intercept
  to suppress system beep); limited for background apps.
- **HotKey library (soffes)**: Minimal wrapper; works but lacks
  built-in configuration UI.

**Key details**:
- Requires Input Monitoring permission (TCC framework)
- Option+Space is NOT a reserved macOS system shortcut (safe default)
- Permission prompt appears on first use; user must approve in
  System Settings > Privacy & Security > Input Monitoring
- KeyboardShortcuts handles storage in UserDefaults automatically

## Decision 3: Text Paste Mechanism

**Decision**: NSPasteboard write + CGEvent Cmd+V simulation, with
Accessibility API detection for clipboard-only fallback.

**Rationale**: This is the most reliable approach across macOS apps
(works in ~95% of applications including text editors, browsers,
and chat apps). Accessibility API (AXUIElement) for detecting focused
text fields provides the fallback trigger.

**Alternatives considered**:
- **AXUIElement direct value manipulation**: Unreliable; setting text
  values on AX elements often doesn't work or isn't visible in the
  target app.
- **CGEvent-only (no pasteboard)**: Less practical; NSPasteboard +
  CGEvent combo is superior.

**Key details**:
- Requires Accessibility permission (separate from Input Monitoring)
- 50-100ms delay needed between pasteboard write and CGEvent post
- Use `AXUIElementCreateSystemWide()` + `kAXFocusedUIElementAttribute`
  to detect if a text field is focused
- If no text field: write to pasteboard only + show notification
- Mark pasteboard data with `org.nspasteboard.TransientType` to
  avoid polluting clipboard history managers

## Decision 4: Audio Capture

**Decision**: AVFoundation (AVAudioEngine) for microphone capture.

**Rationale**: AVFoundation is the standard Apple framework for audio
capture. It's well-documented, supports the default input device,
and handles permission requests natively. The constitution mandates
no third-party audio libraries unless AVFoundation proves insufficient.

**Key details**:
- AVAudioEngine provides a tap on the input node for raw PCM buffers
- Whisper expects 16kHz mono float32 audio — AVAudioEngine can
  resample via format conversion
- Permission request via `AVCaptureDevice.requestAccess(for: .audio)`
- Buffer audio in memory (5 minutes of 16kHz mono ≈ 9.6 MB)

## Decision 5: Text Cleanup

**Decision**: Use Apple Foundation Models (on-device LLM) for
text cleanup via the FoundationModels framework.

**Rationale**: Regex-based filler word removal is brittle and
mangles legitimate uses of words like "like" or "ah". Apple's
on-device language model provides natural language understanding
to distinguish filler words from meaningful content, preserving
the speaker's intent while cleaning up disfluencies. This runs
entirely on-device, satisfying the privacy-first principle.

**Alternatives considered**:
- **Regex patterns**: Simple but brittle; cannot distinguish
  filler "like" from meaningful "like". Rejected.
- **Bundled small LLM (Phi-3-mini via MLX)**: Adds ~2 GB to app
  size and requires managing a second model runtime. Rejected.
- **Whisper-only (no cleanup)**: Simplest, but Whisper doesn't
  reliably remove filler words. Deferred as fallback if Foundation
  Models is unavailable.

**Key details**:
- Requires macOS 26+ (Apple Intelligence)
- Uses `LanguageModelSession` from FoundationModels framework
- Runs on Apple Neural Engine, no network requests
- Prompt instructs model to remove fillers, fix punctuation,
  and preserve original meaning without rephrasing
- Falls back to raw Whisper output if cleanup fails

**Platform impact**: Minimum deployment target raised from
macOS 14 to macOS 26 to access Foundation Models.

## Decision 6: Audio Feedback

**Decision**: Use system sound via NSSound or AudioServicesPlaySystemSound
for start/stop cues.

**Rationale**: Short (<0.5s) audio cues need minimal infrastructure.
System sound APIs are lightweight and don't interfere with the
recording pipeline. Custom .aiff or .caf files bundled in the app
resources provide distinct start and stop sounds.

**Key details**:
- Play sound BEFORE starting recording (so the start sound isn't
  captured in the recording)
- Play stop sound AFTER recording stops
- Keep sounds under 0.5 seconds per FR-004

## Permissions Summary

The app requires two macOS permissions:

1. **Microphone Access** — for audio capture (AVFoundation)
2. **Accessibility** — for paste simulation (CGEvent posting) and
   focused text field detection (AXUIElement)

Input Monitoring is implicitly covered by the Accessibility permission
on macOS 14+. The app should request both on first launch with clear
explanations.
