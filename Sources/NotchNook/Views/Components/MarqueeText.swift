import SwiftUI

/// Scrolling marquee text. Falls back to centred static text when short enough.
struct MarqueeText: View {
    let text: String
    var font: Font = .system(size: 11, weight: .medium)
    var color: Color = .white
    var speed: Double = 30   // pts/sec

    @State private var offset: CGFloat = 0
    @State private var textW: CGFloat  = 0
    @State private var contW: CGFloat  = 0
    @State private var scrolling = false

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
            .onAppear {
                contW = cw
                if textW > cw { startLoop() }
            }
            .onChange(of: text) { _ in
                offset = 0
                scrolling = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if textW > contW { startLoop() }
                }
            }
        }
        .background(
            Text(text)
                .font(font)
                .fixedSize()
                .hidden()
                .background(GeometryReader { g in
                    Color.clear.onAppear { textW = g.size.width }
                })
        )
    }

    private func startLoop() {
        guard !scrolling else { return }
        scrolling = true
        let gap = textW + 30
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard scrolling else { return }
            withAnimation(.linear(duration: gap / speed)) { offset = -gap }
            DispatchQueue.main.asyncAfter(deadline: .now() + gap / speed + 0.5) {
                offset = 0
                scrolling = false
                startLoop()
            }
        }
    }
}
