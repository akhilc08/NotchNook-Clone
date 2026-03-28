import AppKit
import SwiftUI

/// NSHostingView subclass that forwards mouse enter/exit events.
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    var onMouseEntered: (() -> Void)?
    var onMouseExited:  (() -> Void)?
    var onMouseClicked: (() -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) { onMouseEntered?() }
    override func mouseExited(with event: NSEvent)  { onMouseExited?()  }
    override func mouseDown(with event: NSEvent)    { onMouseClicked?() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        wantsLayer = true
        layer?.cornerRadius = 26
        layer?.cornerCurve  = .continuous
        layer?.masksToBounds = true
        layer?.borderWidth = 0
        layer?.borderColor = CGColor(gray: 0, alpha: 0)
        // Bottom corners only — NSHostingView is flipped, so maxY = bottom visually
        layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
}
