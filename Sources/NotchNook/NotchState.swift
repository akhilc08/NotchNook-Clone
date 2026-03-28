import Foundation

@MainActor
final class NotchState: ObservableObject {
    static let shared = NotchState()

    @Published var isExpanded: Bool = false
    @Published var activeTab: Tab = .music

    enum Tab: String, CaseIterable {
        case music     = "music.note"
        case calendar  = "calendar"
        case stats     = "cpu"
        case clipboard = "doc.on.clipboard"
    }

    private init() {}
}
