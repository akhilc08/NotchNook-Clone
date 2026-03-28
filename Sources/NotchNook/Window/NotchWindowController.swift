import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private var window: NSPanel!
    private let state = NotchState.shared
    private var notchRect: CGRect = .zero
    private let expandedW: CGFloat = 540
    private let expandedH: CGFloat = 330
    private var collapseTimer: Timer?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        setupWindow()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupWindow() {
        guard let screen = NSScreen.main else { return }
        notchRect = Self.notchRect(for: screen)

        window = NSPanel(
            contentRect: notchRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Level just above the status bar so we sit in the notch area
        window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        window.backgroundColor  = .clear
        window.isOpaque         = false
        window.hasShadow        = false
        window.ignoresMouseEvents = false
        window.isMovable        = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let root = NotchRootView()
            .environmentObject(NotchState.shared)
            .environmentObject(SpotifyService.shared)
            .environmentObject(CalendarService.shared)
            .environmentObject(SystemStatsService.shared)
            .environmentObject(ClipboardService.shared)

        let hosting = NotchHostingView(rootView: root)
        hosting.onMouseEntered = { [weak self] in self?.mouseEntered() }
        hosting.onMouseExited  = { [weak self] in self?.mouseExited()  }
        window.contentView = hosting
    }

    func showWindow(_ sender: Any?) {
        window.orderFrontRegardless()
    }

    // MARK: - Mouse

    private func mouseEntered() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        guard !state.isExpanded else { return }
        expand()
    }

    private func mouseExited() {
        collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.collapse() }
        }
    }

    // MARK: - Animation

    private func expand() {
        guard let screen = NSScreen.main else { return }
        state.isExpanded = true
        window.hasShadow = true

        let cx = notchRect.midX
        let newFrame = NSRect(
            x: cx - expandedW / 2,
            y: screen.frame.maxY - notchRect.height - expandedH,
            width: expandedW,
            height: notchRect.height + expandedH
        )
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.45
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    private func collapse() {
        state.isExpanded = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(notchRect, display: true)
        } completionHandler: {
            self.window.hasShadow = false
        }
    }

    @objc private func screensChanged() {
        if let screen = NSScreen.main {
            notchRect = Self.notchRect(for: screen)
            if !state.isExpanded {
                window.setFrame(notchRect, display: false)
            }
        }
    }

    // MARK: - Notch Detection

    static func notchRect(for screen: NSScreen) -> CGRect {
        if #available(macOS 12.0, *),
           let left  = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let x = screen.frame.minX + left.maxX
            let w = (screen.frame.minX + right.minX) - x
            let h = left.height
            return CGRect(x: x, y: screen.frame.maxY - h, width: w, height: h)
        }
        // Fallback – best-guess pill for non-notch screens
        let w: CGFloat = 200
        let h: CGFloat = 37
        return CGRect(x: screen.frame.midX - w / 2, y: screen.frame.maxY - h, width: w, height: h)
    }
}
