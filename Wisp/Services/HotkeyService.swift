import AppKit
import Carbon.HIToolbox

final class HotkeyService: @unchecked Sendable {

    private let onToggle: @MainActor () -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(onToggle: @MainActor @escaping () -> Void) {
        self.onToggle = onToggle
    }

    func register() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            let service = Unmanaged<HotkeyService>.fromOpaque(userInfo!).takeUnretainedValue()

            // Re-enable tap if macOS disabled it
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                print("[Wisp] Event tap was disabled by system, re-enabling...")
                if let tap = service.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            // Option+Space: keyCode 49 = Space, check for Option flag
            let isOptionDown = flags.contains(.maskAlternate)
            let noOtherModifiers = !flags.contains(.maskCommand)
                && !flags.contains(.maskControl)
                && !flags.contains(.maskShift)

            if keyCode == 49 && isOptionDown && noOtherModifiers {
                print("[Wisp] Option+Space detected!")
                DispatchQueue.main.async {
                    service.onToggle()
                }
                return nil // consume the event
            }

            return Unmanaged.passUnretained(event)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            print("[Wisp] ERROR: Failed to create event tap.")
            print("[Wisp] You need to grant Accessibility permission.")
            print("[Wisp] Go to: System Settings > Privacy & Security > Accessibility")
            print("[Wisp] Add your terminal app (Terminal, iTerm2, Ghostty, etc.)")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Verify tap is actually enabled
        let enabled = CGEvent.tapIsEnabled(tap: tap)
        print("[Wisp] Hotkey registered: Option+Space (tap enabled: \(enabled))")
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
