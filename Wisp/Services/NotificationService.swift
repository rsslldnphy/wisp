import AppKit

@MainActor
final class NotificationService {

    func show(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        // Run non-modally so it doesn't block the app
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [],
            backing: .buffered,
            defer: true
        )
        alert.beginSheetModal(for: window)

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            window.close()
        }
    }
}
