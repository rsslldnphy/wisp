import AppKit
import SwiftUI

@MainActor
final class LogWindow: NSWindow {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        title = "Transcription Log"
        isReleasedWhenClosed = false
        center()
    }

    func show(entries: [TranscriptionLogEntry]) {
        contentView = NSHostingView(rootView: LogView(entries: entries))
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
