import AppKit
import Foundation

@MainActor
final class ClipboardService: ObservableObject {
    static let shared = ClipboardService()

    @Published var history: [ClipboardItem] = []

    private var timer: Timer?
    private var lastChange: Int = NSPasteboard.general.changeCount
    private let maxHistory = 12

    private init() {}

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkClipboard() }
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount

        if let txt = pb.string(forType: .string), !txt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            insert(ClipboardItem(content: .text(txt)))
        } else if let img = NSImage(pasteboard: pb) {
            insert(ClipboardItem(content: .image(img)))
        }
    }

    private func insert(_ item: ClipboardItem) {
        history.removeAll { $0.isEqual(to: item) }
        history.insert(item, at: 0)
        if history.count > maxHistory { history.removeLast() }
    }

    func copy(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let s):    pb.setString(s, forType: .string)
        case .image(let img): if let t = img.tiffRepresentation { pb.setData(t, forType: .tiff) }
        }
        lastChange = pb.changeCount
    }
}

// MARK: - Model

struct ClipboardItem: Identifiable {
    let id: String
    let content: Content
    let timestamp: Date

    enum Content {
        case text(String)
        case image(NSImage)
    }

    init(content: Content) {
        switch content {
        case .text(let s): id = "txt-" + String(s.prefix(60))
        case .image:       id = "img-" + UUID().uuidString
        }
        self.content   = content
        self.timestamp = Date()
    }

    func isEqual(to other: ClipboardItem) -> Bool { id == other.id }

    var preview: String {
        switch content {
        case .text(let s): return String(s.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        case .image:       return "Image"
        }
    }

    var isImage: Bool { if case .image = content { return true }; return false }
}
