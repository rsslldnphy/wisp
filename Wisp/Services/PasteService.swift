import AppKit

@MainActor
final class PasteService {

    func paste(text: String, completion: @MainActor @escaping (_ fallbackToClipboard: Bool) -> Void) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Mark as transient to avoid polluting clipboard managers
        pasteboard.setData(
            Data(),
            forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        )

        // Use AppleScript via System Events to paste — works reliably
        // even from bare binaries without a bundle
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "v" using command down
            end tell
            """)

        // Small delay to ensure clipboard is settled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var error: NSDictionary?
            script?.executeAndReturnError(&error)
            if let error {
                print("[Wisp] Paste failed: \(error)")
                completion(true)
            } else {
                print("[Wisp] Pasted via System Events")
                completion(false)
            }
        }
    }
}
