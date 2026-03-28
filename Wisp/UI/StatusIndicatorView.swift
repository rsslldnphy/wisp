import AppKit

@MainActor
final class StatusIndicatorView: NSView {

    private let backgroundView: NSVisualEffectView
    private let label: NSTextField
    private let spinner: NSProgressIndicator
    private let recordingDot: NSView

    private var errorDismissWork: DispatchWorkItem?
    var onErrorDismissed: (() -> Void)?

    override init(frame frameRect: NSRect) {
        backgroundView = NSVisualEffectView(frame: frameRect)
        label = NSTextField(labelWithString: "")
        spinner = NSProgressIndicator()
        recordingDot = NSView(frame: NSRect(x: 0, y: 0, width: 12, height: 12))

        super.init(frame: frameRect)

        setupBackground(frameRect)
        // Add all subviews before activating constraints so cross-view anchors are valid
        addSubview(spinner)
        addSubview(recordingDot)
        addSubview(label)
        setupSpinner()
        setupRecordingDot()
        setupLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ state: IndicatorState) {
        errorDismissWork?.cancel()
        errorDismissWork = nil

        switch state {
        case .modelLoading:
            label.stringValue = "Loading model..."
            label.textColor = .secondaryLabelColor
            spinner.isHidden = false
            spinner.startAnimation(nil)
            recordingDot.isHidden = true
            recordingDot.layer?.removeAllAnimations()
            isHidden = false

        case .recording:
            label.stringValue = "Recording..."
            label.textColor = NSColor.systemRed
            spinner.isHidden = true
            spinner.stopAnimation(nil)
            recordingDot.isHidden = false
            addPulseAnimation()
            isHidden = false

        case .transcribing:
            label.stringValue = "Transcribing..."
            label.textColor = NSColor.systemBlue
            spinner.isHidden = false
            spinner.startAnimation(nil)
            recordingDot.isHidden = true
            recordingDot.layer?.removeAllAnimations()
            isHidden = false

        case .error(let message):
            label.stringValue = message
            label.textColor = NSColor.systemOrange
            spinner.isHidden = true
            spinner.stopAnimation(nil)
            recordingDot.isHidden = true
            recordingDot.layer?.removeAllAnimations()
            isHidden = false
            scheduleErrorDismiss()

        case .hidden:
            spinner.stopAnimation(nil)
            recordingDot.layer?.removeAllAnimations()
            recordingDot.isHidden = true
            isHidden = true
        }
    }

    // MARK: - Setup

    private func setupBackground(_ frameRect: NSRect) {
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = frameRect.height / 2
        backgroundView.layer?.masksToBounds = true
        backgroundView.autoresizingMask = [.width, .height]
        addSubview(backgroundView)
    }

    private func setupSpinner() {
        spinner.style = .spinning
        spinner.controlSize = .mini
        spinner.isIndeterminate = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.isHidden = true

        NSLayoutConstraint.activate([
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -5),
            spinner.widthAnchor.constraint(equalToConstant: 12),
            spinner.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    private func setupRecordingDot() {
        recordingDot.wantsLayer = true
        recordingDot.layer?.backgroundColor = NSColor.systemRed.cgColor
        recordingDot.layer?.cornerRadius = 3.5
        recordingDot.translatesAutoresizingMaskIntoConstraints = false
        recordingDot.isHidden = true

        NSLayoutConstraint.activate([
            recordingDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            recordingDot.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -5),
            recordingDot.widthAnchor.constraint(equalToConstant: 7),
            recordingDot.heightAnchor.constraint(equalToConstant: 7),
        ])
    }

    private func setupLabel() {
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 8),
        ])
    }

    // MARK: - Animations

    private func addPulseAnimation() {
        guard let dotLayer = recordingDot.layer else { return }
        dotLayer.removeAllAnimations()

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.3
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        dotLayer.add(pulse, forKey: "pulse")
    }

    private func scheduleErrorDismiss() {
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.update(.hidden)
            self.onErrorDismissed?()
        }
        errorDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }
}
