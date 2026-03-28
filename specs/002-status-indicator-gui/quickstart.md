# Quickstart: Status Indicator GUI

**Feature**: 002-status-indicator-gui
**Date**: 2026-03-28

## What This Feature Does

Adds a floating status indicator at the bottom center of the screen that shows the current app state: model loading (spinner), recording (pulsing dot), transcribing (spinner), or error. The indicator is non-interactive, click-through, and automatically appears/disappears based on state transitions.

## Key Files to Modify

1. **Wisp/Models/AppState.swift** — Add `.loading` case and update transition rules
2. **Wisp/App/AppDelegate.swift** — Start in `.loading` state, wire up indicator to state changes
3. **Wisp/UI/MenuBarController.swift** — Add `.loading` icon for menu bar

## Key Files to Create

1. **Wisp/UI/StatusOverlayWindow.swift** — NSPanel subclass for the floating overlay
2. **Wisp/UI/StatusIndicatorView.swift** — NSView subclass rendering the indicator content (spinner, recording dot, labels)

## Architecture Decisions

- **Pure AppKit**: No SwiftUI per constitution. Animations via Core Animation (CALayer).
- **State-driven**: IndicatorState derived from AppState. Single `updateIndicator()` method drives all UI.
- **Window level toggling**: `.floating` for model loading, above-fullscreen level for recording/transcribing.
- **Active display tracking**: Uses `NSScreen.main` (screen with key window) to position the overlay.

## How to Test

1. Launch app → loading spinner appears at bottom center → disappears when model loaded
2. Press Option+Space → recording indicator appears → release → transcribing spinner appears → disappears when text pasted
3. Test in fullscreen app → loading indicator should NOT appear, recording/transcribing indicators SHOULD appear
4. Test with multiple displays → indicator follows focused window's display
