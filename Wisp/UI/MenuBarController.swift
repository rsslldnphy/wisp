import AppKit

final class MenuBarController {

    private let statusItem: NSStatusItem

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        updateState(.idle)
    }

    func updateState(_ state: AppState) {
        guard let button = statusItem.button else { return }

        switch state {
        case .loading:
            button.image = NSImage(
                systemSymbolName: "hourglass",
                accessibilityDescription: "Wisp — Loading"
            )
        case .idle:
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "Wisp — Idle"
            )
        case .recording:
            button.image = NSImage(
                systemSymbolName: "mic.fill",
                accessibilityDescription: "Wisp — Recording"
            )
        case .processing:
            button.image = NSImage(
                systemSymbolName: "ellipsis.circle",
                accessibilityDescription: "Wisp — Processing"
            )
        }
    }

    func playStartSound() {
        playSound(named: "record-start")
    }

    func playStopSound() {
        playSound(named: "record-stop")
    }

    private func playSound(named name: String) {
        guard let url = Bundle.module.url(forResource: name, withExtension: "wav") else {
            print("[Wisp] Sound not found: \(name).wav")
            return
        }
        let sound = NSSound(contentsOf: url, byReference: true)
        sound?.play()
    }
}
