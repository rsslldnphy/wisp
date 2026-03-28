import AppKit
import Carbon
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

        guard AXIsProcessTrusted() else {
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
            print("[Wisp] Accessibility not granted — falling back to clipboard")
            completion(true)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)
            // Look up the key that produces 'v' on the active layout so this
            // works correctly on Dvorak and other non-QWERTY keyboards.
            let vKey = Self.keyCode(for: "v") ?? 0x09

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

            print("[Wisp] Pasted via CGEvent (keyCode: \(vKey))")
            completion(false)
        }
    }

    /// Returns the virtual key code that produces `character` on the current
    /// keyboard layout, or nil if not found.
    private static func keyCode(for character: Character) -> CGKeyCode? {
        guard
            let unmanagedSource = TISCopyCurrentKeyboardInputSource(),
            let layoutDataPtr = TISGetInputSourceProperty(
                unmanagedSource.takeRetainedValue(),
                kTISPropertyUnicodeKeyLayoutData
            )
        else { return nil }

        let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataPtr).takeUnretainedValue()
        let keyboardLayout = unsafeBitCast(
            CFDataGetBytePtr(layoutData),
            to: UnsafePointer<UCKeyboardLayout>.self
        )
        let target = UniChar(character.unicodeScalars.first!.value)

        for keyCode in 0 ..< 128 {
            var deadKeyState: UInt32 = 0
            var output = [UniChar](repeating: 0, count: 4)
            var outputLength = 0

            UCKeyTranslate(
                keyboardLayout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDown),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                4,
                &outputLength,
                &output
            )

            if outputLength == 1 && output[0] == target {
                return CGKeyCode(keyCode)
            }
        }
        return nil
    }
}
