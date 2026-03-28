import AppKit
import CoreGraphics

@MainActor
final class PasteService {

    func paste(text: String, completion: @MainActor @escaping (_ fallbackToClipboard: Bool) -> Void) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setData(
            Data(),
            forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)
            let vKey: CGKeyCode = 0x09 // kVK_ANSI_V

            guard
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
                let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
            else {
                completion(true)
                return
            }

            keyDown.flags = .maskCommand
            keyUp.flags   = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            keyUp.post(tap: .cgAnnotatedSessionEventTap)

            print("[Wisp] Pasted via CGEvent")
            completion(false)
        }
    }
}
