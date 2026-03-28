import KeyboardShortcuts

final class HotkeyService: @unchecked Sendable {

    private let onToggle: @MainActor () -> Void
    private var isActive = false

    init(onToggle: @MainActor @escaping () -> Void) {
        self.onToggle = onToggle
    }

    func register() {
        isActive = true
        KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in
            guard let self, self.isActive else { return }
            let toggle = self.onToggle
            Task { @MainActor in toggle() }
        }
        print("[Wisp] Hotkey registered via KeyboardShortcuts")
    }

    func unregister() {
        isActive = false
    }
}
