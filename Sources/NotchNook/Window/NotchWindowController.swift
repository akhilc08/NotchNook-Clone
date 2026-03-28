import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private var window: NSPanel!
    private let state = NotchState.shared
    private var notchRect: CGRect = .zero      // raw notch bounds from screen
    private var compactRect: CGRect = .zero    // slightly inset — avoids peeking past the physical notch
    private let expandedW: CGFloat = 500
    private let expandedH: CGFloat = 250
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
        notchRect   = Self.notchRect(for: screen)
        compactRect = Self.compactRect(from: notchRect)

        window = NSPanel(
            contentRect: compactRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        window.backgroundColor    = .clear
        window.isOpaque           = false
        window.hasShadow          = false
        window.ignoresMouseEvents = false
        window.isMovable          = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let root = NotchRootView()
            .environmentObject(NotchState.shared)
            .environmentObject(SpotifyService.shared)
            .environmentObject(CalendarService.shared)
            .environmentObject(ClipboardService.shared)

        let hosting = NotchHostingView(rootView: root)
        hosting.onMouseEntered = { [weak self] in self?.mouseEntered() }
        hosting.onMouseExited  = { [weak self] in self?.mouseExited()  }
        hosting.onMouseClicked = { [weak self] in self?.mouseClicked() }
        window.contentView = hosting
    }

    func showWindow(_ sender: Any?) {
        window.orderFrontRegardless()
    }

    // MARK: - Mouse

    private func mouseEntered() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        if !state.isExpanded {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    private func mouseExited() {
        collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.collapse() }
        }
    }

    private func mouseClicked() {
        guard !state.isExpanded else { return }
        expand()
    }

    // MARK: - Animation

    private func expand() {
        guard let screen = NSScreen.main else { return }
        state.isExpanded = true

        let cx = notchRect.midX
        let newFrame = NSRect(
            x: cx - expandedW / 2,
            y: screen.frame.maxY - notchRect.height - expandedH,
            width: expandedW,
            height: notchRect.height + expandedH
        )
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.45
            // Spring-like ease-out: cubic-bezier(0.22, 1.0, 0.36, 1.0)
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    private func collapse() {
        state.isExpanded = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(compactRect, display: true)
        }
    }

    @objc private func screensChanged() {
        guard let screen = NSScreen.main else {
            // Screen unavailable (e.g. external monitor disconnected while expanded)
            if state.isExpanded { collapse() }
            return
        }
        notchRect   = Self.notchRect(for: screen)
        compactRect = Self.compactRect(from: notchRect)
        if !state.isExpanded {
            window.setFrame(compactRect, display: false)
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
        let w: CGFloat = 200
        let h: CGFloat = 37
        return CGRect(x: screen.frame.midX - w / 2, y: screen.frame.maxY - h, width: w, height: h)
    }

    /// Trim the compact strip so it sits fully inside the physical notch:
    /// 4 pts narrower on each side, and 5 pts shorter from the bottom so the
    /// lower edge doesn't peek below the notch into the visible display area.
    static func compactRect(from notch: CGRect) -> CGRect {
        CGRect(
            x:      notch.minX + 4,
            y:      notch.minY + 5,          // raise bottom edge into the notch
            width:  notch.width - 8,
            height: notch.height - 5
        )
    }
}
