# Data Model: Status Indicator GUI

**Feature**: 002-status-indicator-gui
**Date**: 2026-03-28

## Entities

### AppState (Modified)

Existing enum extended with a new case.

- **loading**: App is starting and the speech recognition model is being loaded. Initial state on launch.
- **idle**: Model loaded, ready for dictation. No indicator shown.
- **recording**: User is actively recording audio. Recording indicator shown.
- **processing**: Audio is being transcribed. Transcription loading indicator shown.

**Transition rules**:
```
loading -> idle        (model loaded successfully)
loading -> error       (model failed to load — transient, auto-returns to loading or idle)
idle -> recording      (user triggers hotkey)
recording -> processing (user stops recording)
processing -> idle     (transcription complete, text pasted)
processing -> error    (transcription failed — transient, auto-returns to idle)
```

**New constraint**: `.loading` cannot transition to `.recording` — recording is blocked until model is ready.

### IndicatorState

Represents the visual state of the floating overlay. Derived from AppState but includes error sub-states.

- **modelLoading**: Spinner + "Loading model..." label. Window level: floating (below fullscreen).
- **recording**: Pulsing red dot + "Recording..." label. Window level: above fullscreen.
- **transcribing**: Spinner + "Transcribing..." label. Window level: above fullscreen.
- **error(message)**: Error icon + message label. Auto-dismisses after 3 seconds.
- **hidden**: Indicator not visible (idle state).

**Relationships**:
- AppState `.loading` → IndicatorState `.modelLoading`
- AppState `.idle` → IndicatorState `.hidden`
- AppState `.recording` → IndicatorState `.recording`
- AppState `.processing` → IndicatorState `.transcribing`
- Any error during transition → IndicatorState `.error(message)` → then appropriate next state

### StatusOverlayWindow

The floating panel that hosts the indicator view.

**Attributes**:
- Position: Bottom center of active screen (NSScreen.main)
- Size: Compact pill shape (~200x44 pt, content-dependent)
- Window level: Dynamic based on IndicatorState
- Behavior: Non-activating, click-through, no shadow, joins all Spaces
- Lifecycle: Created once at app launch, shown/hidden by state changes

### StatusIndicatorView

The content view inside the overlay window.

**Attributes**:
- Background: Translucent dark material (vibrancy)
- Corner radius: Pill shape (height / 2)
- Content: Icon/animation + label, centered horizontally
- Animations: Smooth fade transitions between states
