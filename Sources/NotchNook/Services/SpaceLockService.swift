import Cocoa
import ApplicationServices

/// Blocks Mission Control space-switching gestures and keyboard shortcuts
/// while active, keeping the user locked to their current Space.
final class SpaceLockService {
    static let shared = SpaceLockService()

    private(set) var isLocked = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func toggle(menuItem: NSMenuItem?) {
        isLocked ? disable() : enable()
        menuItem?.title = isLocked ? "Unlock Space" : "Lock to Current Space"
        menuItem?.state = isLocked ? .on : .off
    }

    private func enable() {
        guard checkAccessibility() else { return }

        // Intercept keyDown (Ctrl+arrow space shortcuts) + gesture events (type 29)
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << 29)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: spaceLockEventCallback,
            userInfo: nil
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        isLocked = true
    }

    private func disable() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        isLocked = false
    }

    @discardableResult
    private func checkAccessibility() -> Bool {
        if AXIsProcessTrusted() { return true }
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        return false
    }
}

// MARK: - CGEventTap callback (must be a free function, called on any thread)

private func spaceLockEventCallback(
    _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Block Ctrl+Left / Ctrl+Right — standard keyboard Space-switching shortcuts
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if event.flags.contains(.maskControl), keyCode == 123 || keyCode == 124 {
            return nil
        }
    }

    // Block horizontal three-finger swipes (NSEvent.EventType.gesture = 29)
    if type.rawValue == 29,
       let ns = NSEvent(cgEvent: event) {
        let dx = abs(ns.deltaX), dy = abs(ns.deltaY)
        if dx > dy && dx > 3 { return nil }
    }

    return Unmanaged.passRetained(event)
}
