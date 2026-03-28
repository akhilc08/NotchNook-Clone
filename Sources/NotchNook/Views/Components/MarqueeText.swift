import SwiftUI

private struct TextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Scrolling marquee text. Falls back to centred static text when short enough.
struct MarqueeText: View {
    let text: String
    var font: Font = .system(size: 11, weight: .medium)
    var color: Color = .white
    var speed: Double = 30   // pts/sec

    @State private var offset:     CGFloat = 0
    @State private var textW:      CGFloat = 0
    @State private var contW:      CGFloat = 0
    @State private var scrollTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let cw = geo.size.width
            ZStack(alignment: .leading) {
                if textW > cw {
                    Text(text + "     " + text)
                        .font(font)
                        .foregroundStyle(color)
                        .fixedSize()
                        .offset(x: offset)
                } else {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .clipped()
            .onAppear { contW = cw }
        }
        // Measure text width via PreferenceKey so it updates on every text change,
        // not just on initial appear.
        .background(
            Text(text)
                .font(font)
                .fixedSize()
                .hidden()
                .background(GeometryReader { g in
                    Color.clear.preference(key: TextWidthKey.self, value: g.size.width)
                })
        )
        .onPreferenceChange(TextWidthKey.self) { newW in
            textW = newW
            restartLoopIfNeeded()
        }
        .onDisappear {
            scrollTask?.cancel()
        }
    }

    // MARK: - Loop

    private func restartLoopIfNeeded() {
        scrollTask?.cancel()
        scrollTask = nil
        offset = 0
        guard textW > contW, contW > 0 else { return }
        startLoop()
    }

    private func startLoop() {
        let gap = textW + 30
        // Cancel any previous loop before starting a new one.
        scrollTask?.cancel()
        scrollTask = Task {
            // Initial pause before first scroll
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: gap / speed)) { offset = -gap }
            // Wait for animation + brief pause before looping
            try? await Task.sleep(nanoseconds: UInt64((gap / speed + 0.5) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            offset = 0
            startLoop()
        }
    }
}
