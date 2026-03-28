import AppKit
@preconcurrency import AVFoundation
@preconcurrency import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var state: AppState = .loading
    private var currentSession: DictationSession?

    private var hotkeyService: HotkeyService?
    private var audioCaptureService: AudioCaptureService?
    private var transcriptionService: TranscriptionService?
    private var textCleanupService: TextCleanupService?
    private var pasteService: PasteService?
    private var menuBarController: MenuBarController?
    private var notificationService: NotificationService?
    private var overlayWindow: StatusOverlayWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupOverlay()
        requestPermissions()
        setupServices()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        menuBarController = MenuBarController(statusItem: statusItem!)
        menuBarController?.updateState(.loading)

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Quit Wisp",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: ""
            )
        )
        statusItem?.menu = menu
    }

    private func setupOverlay() {
        overlayWindow = StatusOverlayWindow()
        overlayWindow?.show(state: .modelLoading)
    }

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                DispatchQueue.main.async { [weak self] in
                    self?.notificationService?.show(
                        title: "Microphone Access Required",
                        message: "Wisp needs microphone access to record dictation. "
                            + "Enable it in System Settings > Privacy & Security > Microphone."
                    )
                }
            }
        }

        nonisolated(unsafe) let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            notificationService?.show(
                title: "Accessibility Access Required",
                message: "Wisp needs Accessibility access to paste text into other apps. "
                    + "Enable it in System Settings > Privacy & Security > Accessibility."
            )
        }
    }

    private func setupServices() {
        notificationService = NotificationService()
        textCleanupService = TextCleanupService()
        pasteService = PasteService()
        audioCaptureService = AudioCaptureService()
        transcriptionService = TranscriptionService()

        hotkeyService = HotkeyService { [weak self] in
            self?.handleHotkeyToggle()
        }
        hotkeyService?.register()

        // Preload Whisper model and warm up Core ML compilation
        Task {
            do {
                try await transcriptionService?.loadModel()
                print("[Wisp] Model loaded, warming up...")
                // Transcribe 1 second of silence to trigger Core ML graph compilation
                let silentBuffer = Data(count: Int(16000 * 4)) // 1s of 16kHz float32 zeros
                _ = try? await transcriptionService?.transcribe(audioBuffer: silentBuffer)
                print("[Wisp] Ready — press Option+Space to dictate")
                transitionToIdle()
            } catch {
                print("[Wisp] WARNING: Model failed to load: \(error)")
                print("[Wisp] Transcription will retry on first dictation")
                overlayWindow?.show(state: .error("Model failed to load"))
                // After error auto-dismisses, transition to idle so user can still try
                transitionToIdle()
            }
        }
    }

    private func transitionToIdle() {
        if case .success(let newState) = state.transition(to: .idle) {
            state = newState
            menuBarController?.updateState(.idle)
            overlayWindow?.hide()
        }
    }

    // MARK: - Dictation Flow

    private func handleHotkeyToggle() {
        print("[Wisp] handleHotkeyToggle, state: \(state)")
        switch state {
        case .loading:
            print("[Wisp] Ignoring hotkey — model still loading")
        case .idle:
            startRecording()
        case .recording:
            stopRecordingAndTranscribe()
        case .processing:
            print("[Wisp] Ignoring hotkey during processing")
        }
    }

    private func startRecording() {
        guard case .success(let newState) = state.transition(to: .recording) else {
            print("[Wisp] State transition to recording failed")
            return
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("[Wisp] Mic authorization status: \(micStatus.rawValue)")
        guard micStatus == .authorized else {
            print("[Wisp] Mic not authorized")
            notificationService?.show(
                title: "Microphone Unavailable",
                message: "Wisp cannot access the microphone. Check System Settings."
            )
            return
        }

        state = newState
        print("[Wisp] Recording started")
        menuBarController?.updateState(state)
        menuBarController?.playStartSound()
        overlayWindow?.show(state: .recording)

        currentSession = DictationSession()

        audioCaptureService?.startRecording { [weak self] result in
            DispatchQueue.main.async {
                self?.handleAutoStop(result: result)
            }
        }
    }

    private func stopRecordingAndTranscribe() {
        guard case .success(let newState) = state.transition(to: .processing) else {
            print("[Wisp] State transition to processing failed")
            return
        }

        print("[Wisp] Stopping recording...")
        menuBarController?.playStopSound()
        state = newState
        menuBarController?.updateState(state)
        overlayWindow?.show(state: .transcribing)

        currentSession?.stop()
        guard let session = currentSession else {
            print("[Wisp] No active session")
            return
        }

        print("[Wisp] Session duration: \(session.audioDuration)s")

        // Check minimum duration
        if session.audioDuration < 0.5 {
            print("[Wisp] Recording too short, discarding")
            handleResult(.discarded(reason: .tooShort))
            return
        }

        guard let audioBuffer = audioCaptureService?.stopRecording() else {
            print("[Wisp] No audio buffer returned")
            handleResult(.failed(error: .microphoneUnavailable))
            return
        }

        print("[Wisp] Audio buffer: \(audioBuffer.count) bytes, transcribing...")

        Task {
            await transcribeAndPaste(audioBuffer: audioBuffer)
        }
    }

    private func handleAutoStop(result: AudioCaptureService.AutoStopResult) {
        guard state == .recording else { return }
        switch result {
        case .maxDurationReached(let buffer):
            guard case .success(let newState) = state.transition(to: .processing) else {
                return
            }
            menuBarController?.playStopSound()
            state = newState
            menuBarController?.updateState(state)
            overlayWindow?.show(state: .transcribing)
            currentSession?.stop()
            notificationService?.show(
                title: "Maximum Duration Reached",
                message: "Recording stopped after 5 minutes."
            )
            Task {
                await transcribeAndPaste(audioBuffer: buffer)
            }
        }
    }

    private func transcribeAndPaste(audioBuffer: Data) async {
        do {
            print("[Wisp] Loading model and transcribing...")
            let rawText = try await transcriptionService?.transcribe(audioBuffer: audioBuffer)
            print("[Wisp] Raw transcription: \(rawText ?? "<nil>")")
            guard let rawText, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                print("[Wisp] No speech detected, discarding")
                await MainActor.run { handleResult(.discarded(reason: .noSpeechDetected)) }
                return
            }
            print("[Wisp] Cleaning up text...")
            let cleanedText: String
            if let service = textCleanupService {
                cleanedText = (try? await service.cleanup(rawText)) ?? rawText
            } else {
                cleanedText = rawText
            }
            print("[Wisp] Cleaned text: \(cleanedText)")

            await MainActor.run {
                pasteService?.paste(text: cleanedText) { [weak self] fallbackToClipboard in
                    if fallbackToClipboard {
                        self?.notificationService?.show(
                            title: "Text Copied to Clipboard",
                            message: "No text field detected. Use Cmd+V to paste."
                        )
                    }
                }
                handleResult(.completed(text: cleanedText))
            }
        } catch let error as TranscriptionError {
            await MainActor.run { handleResult(.failed(error: error)) }
        } catch {
            await MainActor.run {
                handleResult(.failed(error: .processingFailed(message: error.localizedDescription)))
            }
        }
    }

    private func handleResult(_ result: TranscriptionResult) {
        currentSession?.complete(with: result)
        currentSession = nil

        switch result {
        case .completed:
            break
        case .discarded(let reason):
            switch reason {
            case .tooShort:
                notificationService?.show(
                    title: "Recording Too Short",
                    message: "Speak for at least half a second."
                )
            case .noSpeechDetected:
                notificationService?.show(
                    title: "No Speech Detected",
                    message: "No recognizable speech was found in the recording."
                )
            }
        case .failed(let error):
            overlayWindow?.show(state: .error(describeError(error)))
            notificationService?.show(
                title: "Transcription Failed",
                message: describeError(error)
            )
        }

        state = .idle
        menuBarController?.updateState(.idle)
        overlayWindow?.hide()
    }

    private func describeError(_ error: TranscriptionError) -> String {
        switch error {
        case .modelNotLoaded:
            return "Speech recognition model is not available."
        case .processingFailed(let message):
            return "Processing error: \(message)"
        case .microphoneUnavailable:
            return "Microphone is not accessible."
        case .permissionDenied:
            return "Microphone permission was denied."
        }
    }
}
