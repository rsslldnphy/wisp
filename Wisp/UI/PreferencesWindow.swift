import AppKit
import SwiftUI

@MainActor
final class PreferencesWindow: NSWindowController {

    static var shared: PreferencesWindow?

    static func show(
        preferences: PreferencesStore,
        microphoneList: MicrophoneList,
        wordDictionary: WordDictionaryStore
    ) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let controller = PreferencesWindow(
            preferences: preferences,
            microphoneList: microphoneList,
            wordDictionary: wordDictionary
        )
        shared = controller
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private init(
        preferences: PreferencesStore,
        microphoneList: MicrophoneList,
        wordDictionary: WordDictionaryStore
    ) {
        let view = PreferencesView(
            preferences: preferences,
            microphoneList: microphoneList,
            wordDictionary: wordDictionary
        )
        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Wisp Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 520, height: 560))
        window.minSize = NSSize(width: 480, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        // Escape key closes the window without saving (promptDraft is local @State,
        // so uncommitted edits are discarded automatically when the view is destroyed).
        window.standardWindowButton(.closeButton)?.target = nil

        super.init(window: window)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    required init?(coder: NSCoder) { nil }

    @objc private func windowWillClose(_ notification: Notification) {
        PreferencesWindow.shared = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
