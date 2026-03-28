import Foundation
import SwiftUI

@MainActor
final class NotchState: ObservableObject {
    static let shared = NotchState()

    @Published var isExpanded: Bool = false
    @Published var activeTab:  Tab  = .music

    enum Tab: String, CaseIterable {
        case music        = "music.note"
        case calendar     = "calendar"
        case clipboard    = "doc.on.clipboard"
        case productivity = "timer"

        var accessibilityLabel: String {
            switch self {
            case .music:        return "Music"
            case .calendar:     return "Calendar"
            case .clipboard:    return "Clipboard"
            case .productivity: return "Productivity"
            }
        }
    }

    private init() {}
}

// MARK: - Theme

enum NotchTheme {
    static let panelColor = Color.black
    /// Blue — the single brand accent used across all active states and CTAs.
    static let accent = Color(red: 0.30, green: 0.45, blue: 0.82)

    /// Opacity values calibrated for WCAG AA contrast (≥4.5:1) on pure black.
    enum Opacity {
        /// Primary content — full visibility.
        static let primary:   Double = 1.0
        /// Secondary informative text — ≈8.3:1 contrast on black (WCAG AA+).
        static let secondary: Double = 0.65
        /// Tertiary informative text — ≈6.3:1 contrast on black (WCAG AA).
        static let tertiary:  Double = 0.55
        /// Decorative-only chrome — below AA threshold. Never use for informative text.
        static let ghost:     Double = 0.20
    }
}
