# Quickstart: Polish and Cleanup

**Branch**: `006-polish-and-cleanup` | **Date**: 2026-03-29

## Three independent changes — each can be built and tested separately

---

### 1. Ghost Icon

**What to build**:
- Create or procure a simple circular ghost SVG/PDF (round head, scalloped or wavy base, two dot eyes; monochrome, template-mode).
- Add it to `Wisp/Resources/Assets.xcassets` as `StatusBarIcon`, Render As: Template Image.
- In `MenuBarController.updateState()`, replace the `"waveform"` SF Symbol used for the `.idle` state with `NSImage(named: "StatusBarIcon")`.

**How to verify**:
1. Build and run. The menu bar icon in the idle state shows the ghost.
2. Toggle dark/light mode — icon remains visible and inverts correctly.
3. Start a recording session — icon reverts to `mic.fill` (existing behaviour unchanged).

---

### 2. Beep Timing Fix

**What to build**:
- In `MenuBarController`, conform to `NSSoundDelegate`.
- Add `playStartSound(completion: @escaping () -> Void)` — stores the closure, sets `sound.delegate = self`, calls `sound.play()`.
- In `sound(_:didFinishPlaying:)`, fire the stored closure.
- Add a fallback: if the delegate never fires within 1000 ms, fire the closure anyway (use a `DispatchWorkItem` that is cancelled on delegate callback).
- In `AppDelegate`, replace the two-step `playStartSound()` + `startRecording(...)` with:
  ```swift
  menuBarController?.playStartSound {
      self.audioCaptureService?.startRecording(autoStopHandler: ...)
  }
  ```

**How to verify**:
1. Trigger dictation with the MacBook's built-in microphone and speakers at medium volume.
2. Say nothing — just let the session run for 2 seconds.
3. Stop the session. The transcript should be empty (or contain only silence artefacts), never the beep sound.
4. Repeat 5 times — beep should never appear in transcript.

---

### 3. Launch on Startup

**What to build**:
- Add `launchOnStartup: Bool` to `PreferencesStore` with `UserDefaults` backing.
- On `didSet`, call `SMAppService.mainApp.register()` or `.unregister()`; handle errors with `NSAlert`.
- On app launch, reconcile stored value with `SMAppService.mainApp.status`.
- In `AppDelegate.setupMenuBar()`, add a "Launch on Startup" `NSMenuItem` above the separator, with state bound to `PreferencesStore.launchOnStartup`.
- Add corresponding `Toggle` to `PreferencesView`.

**How to verify**:
1. Open the menu. "Launch on Startup" item is present and unchecked by default.
2. Click it. Checkmark appears. Open System Settings > General > Login Items — Wisp is listed.
3. Quit and log out, log back in — Wisp launches automatically.
4. Open the menu. Click "Launch on Startup" again. Checkmark disappears.
5. Quit and log out, log back in — Wisp does NOT launch automatically.
6. Remove Wisp from Login Items in System Settings manually, then relaunch Wisp — the menu item shows unchecked (reconciliation worked).
