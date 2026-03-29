# Research: Escape Cancel Countdown with Progress Bar

## Decision 1: Progress Bar Animation Strategy

**Decision**: Use a `CABasicAnimation` on a custom layer-backed `NSView` (fill bar) owned by `StatusIndicatorView`, driven by a fixed 3-second animation duration. The view starts/stops the animation itself when the `IndicatorState.cancelling` case is applied; `AppDelegate` does not push per-frame progress values.

**Rationale**: Core Animation runs on the render server — it is not affected by main-thread load and does not require a `Timer` or `CADisplayLink`. The 3-second countdown duration is fixed by the spec, so a `CABasicAnimation(keyPath: "bounds.size.width")` from full width to zero is sufficient. Cancelling the animation mid-flight (second Escape) is handled by `layer.removeAllAnimations()` when the state changes.

**Alternatives considered**:
- `NSProgressIndicator` in determinate mode — rejected because it renders as a thin bar with macOS-system styling that does not match the pill-shaped HUD. Custom `NSView` gives full control over shape and colour.
- `Timer` firing every 50 ms updating an `IndicatorState.cancelling(progress: Double)` value — rejected because it requires main-thread scheduling and makes `IndicatorState` non-trivially `Equatable`. The view can own the animation entirely.

---

## Decision 2: AppState Extension vs. AppDelegate Flag

**Decision**: Add `case cancelling` to `AppState` and add new valid transitions `recording → cancelling`, `cancelling → processing`, and `cancelling → idle` (for too-short recordings). Keep `processing` as a single case; whether to paste is tracked by a `shouldPasteAfterProcessing: Bool` property on `AppDelegate`.

**Rationale**: `AppState` should reflect every real, user-visible state of the app; "a countdown is running" is distinctly different from "transcription is in progress". Adding a state to `AppState` keeps the state machine as the single source of truth, consistent with the type-safety constitution principle. Tracking paste intent separately avoids adding associated values to `.processing`, which would ripple into `IndicatorState.from(_:)` and all switch sites.

**Alternatives considered**:
- Keeping `AppState` unchanged and using a flag in `AppDelegate` to represent the cancelling phase — rejected because it splits authoritative state across two objects, undermining the state machine.
- `case processing(shouldPaste: Bool)` — rejected because it would require updating every switch statement that matches `.processing`, including `IndicatorState.from(_:)` and `handleHotkeyToggle()`, for zero user-visible benefit over a simple Boolean flag.

---

## Decision 3: Audio Buffer Retention During Countdown

**Decision**: When the first Escape is pressed, audio capture is stopped immediately and the resulting `Data` buffer is stored in a `pendingAudioBuffer: Data?` property on `AppDelegate`. The countdown task is started. On countdown expiry the buffer is passed to `transcribeAndSave`; on second Escape it is passed to `transcribeAndPaste`.

**Rationale**: The spec requires the HUD to disappear after the countdown while transcription continues "silently in the background." Stopping the microphone at the moment Escape is pressed (not at countdown expiry) is correct — the user intends to stop recording; the countdown is only about the paste decision. Retaining the buffer as a typed `Data?` property is minimal and safe; it is cleared after the transcription task receives it.

**Alternatives considered**:
- Keeping the microphone open during the countdown — rejected because it would capture unintended audio while the user decides.
- Wrapping the buffer in an `actor` — rejected; `AppDelegate` is already `@MainActor`, making a plain property assignment safe.

---

## Decision 4: TranscriptionLogEntry `wasPasted` Field

**Decision**: Add `let wasPasted: Bool` to `TranscriptionLogEntry` with a backward-compatible JSON decoder default of `true`. Update `TranscriptionLogStore.append(text:wasPasted:)` to accept the flag. Update `LogView` to visually distinguish not-pasted entries (e.g., a dimmed "not pasted" annotation).

**Rationale**: The spec requires log entries from cancelled transcriptions to be distinguishable (FR-008). A Boolean field is the minimal, testable change. Defaulting absent JSON keys to `true` via a custom `init(from:)` ensures existing log files decode without error.

**Alternatives considered**:
- Separate log files for pasted vs. not-pasted entries — rejected as over-engineering for this distinction.
- An enum `LogEntryOutcome` — rejected as speculative; Boolean is sufficient and the simplest representation.

---

## Decision 5: Countdown Task Ownership

**Decision**: `AppDelegate` owns a `cancelCountdownTask: Task<Void, Never>?` property. The task is created in `beginCancelCountdown()` and cancelled (`.cancel()`) in `restoreFromCancelling()`. The task body uses `try await Task.sleep(for: .seconds(3))` wrapped in a `do/catch CancellationError` block.

**Rationale**: Swift Structured Concurrency's cooperative cancellation is the idiomatic way to cancel an in-flight delay. The `Task` handle stored on the coordinator (`AppDelegate`) follows the same pattern already used for audio recording tasks in the codebase.

**Alternatives considered**:
- `DispatchWorkItem` — rejected in favour of Swift Concurrency, which is already used throughout the codebase.
- Letting the `StatusIndicatorView` own the countdown timer — rejected; view should not own business-logic state. The view manages animation; the coordinator manages timing.
