# Research: Status Indicator GUI

**Feature**: 002-status-indicator-gui
**Date**: 2026-03-28

## R-001: Floating Overlay Window on macOS

**Decision**: Use an NSPanel (borderless, non-activating) as the floating overlay window.

**Rationale**: NSPanel is the standard AppKit class for floating utility windows. With `styleMask: [.borderless, .nonactivatingPanel]` and `NSWindow.Level.floating` (or `.screenSaver` for above-fullscreen), it remains visible without stealing focus or appearing in the Cmd+Tab switcher. Setting `isMovableByWindowBackground = false`, `ignoresMouseEvents = true`, and `hasShadow = false` makes it fully click-through and unobtrusive.

**Alternatives considered**:
- NSWindow: Would work but lacks the built-in non-activating behavior of NSPanel.
- CALayer overlay: Not suitable for cross-app floating overlays; only works within the app's own windows.
- NSPopover: Anchored to a view, not suitable for screen-positioned overlays.

## R-002: Window Level Management for Fullscreen Apps

**Decision**: Use `NSWindow.Level.floating` for the model-loading state (normal overlay, hidden behind fullscreen apps). Switch to `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))` or `.screenSaver` for recording/transcribing states to appear above fullscreen apps.

**Rationale**: Per the clarification, the indicator should only appear above fullscreen apps during recording and transcribing. The `.floating` level sits above normal windows but below fullscreen spaces. The `.screenSaver` level (or a custom high level) sits above fullscreen apps. Toggling the window level on state transitions achieves the desired behavior.

**Alternatives considered**:
- Using `.statusBar` level: Inconsistent behavior with fullscreen spaces on different macOS versions.
- Always using `.screenSaver`: Would violate the spec requirement that loading state does not appear above fullscreen.
- NSWindow.collectionBehavior with `.canJoinAllSpaces` + `.fullScreenAuxiliary`: Needed in addition to window level to ensure the panel follows across Spaces.

## R-003: Tracking Active Display (Focused Window)

**Decision**: Use `NSScreen.main` which returns the screen containing the window that currently has keyboard focus. Recalculate position on state transitions and observe `NSApplication.didChangeScreenParametersNotification` for display configuration changes.

**Rationale**: `NSScreen.main` reflects the screen with the key window (focused window), which matches the spec requirement. The overlay position should be recalculated each time the indicator appears or changes state so it tracks display changes.

**Alternatives considered**:
- `NSEvent.mouseLocation` + `NSScreen.screens`: Tracks mouse, not focused window. Not what the spec requires.
- `NSWorkspace` active app notifications: More complex and doesn't directly give the screen of the focused window.

## R-004: AppKit vs SwiftUI for Overlay Content

**Decision**: Use pure AppKit (NSView subclasses) for the overlay content.

**Rationale**: The constitution states "AppKit for menu bar integration; SwiftUI permitted for settings/preferences panels only." The floating overlay is not a settings panel. The indicator content is simple — an animated spinner, a recording dot, and text labels — all easily achievable with Core Animation (CALayer, CABasicAnimation) or NSProgressIndicator. Staying in pure AppKit avoids introducing SwiftUI as a dependency for non-settings UI and respects the constitution.

**Alternatives considered**:
- SwiftUI via NSHostingView: Would simplify animation code but technically violates the constitution's UI framework constraint. The overlay is not a settings panel.
- NSVisualEffectView + NSProgressIndicator: A viable subset of the chosen approach — may be used for the loading spinner specifically.

## R-005: State Machine Extension

**Decision**: Add a `.loading` case to `AppState` to represent the model-loading state explicitly. Update transition rules to allow `.loading -> .idle` (model loaded) and prevent `.loading -> .recording` (must wait for model).

**Rationale**: The current AppState has `.idle`, `.recording`, `.processing`. The spec requires a visible loading state during model initialization. Making this an explicit state in the state machine ensures the indicator can react to it and prevents recording while the model is loading (edge case from spec). The app starts in `.loading` instead of `.idle`.

**Alternatives considered**:
- Separate boolean `isModelLoading` on AppDelegate: Would bypass the state machine, creating a parallel state that's harder to reason about. Violates the existing pattern.
- Observable property on TranscriptionService: Would decouple the loading state from the indicator, requiring separate observation. Less clean.

## R-006: Error State Display Duration

**Decision**: Error indicators auto-dismiss after 3 seconds, matching the existing NotificationService behavior.

**Rationale**: The spec requires error states (FR-007) but doesn't specify duration. The existing NotificationService auto-dismisses after 3 seconds. Using the same duration provides consistent UX.

**Alternatives considered**:
- 5 seconds: Longer than needed for a brief error message.
- Manual dismiss: The spec says the indicator requires no user interaction.
