import SwiftUI

struct AudioWaveView: View {
    var color: Color = .green
    var isAnimating: Bool = true

    @State private var phase: Bool = false

    private let lo: [CGFloat] = [6, 12, 8, 5]
    private let hi: [CGFloat] = [14, 6, 16, 10]

    var body: some View {
        HStack(spacing: 1.5) {
            bar(0); bar(1); bar(2); bar(3)
        }
        .onAppear { phase = isAnimating }
        .onChange(of: isAnimating) { _, newValue in
            phase = newValue
        }
    }

    private func bar(_ i: Int) -> some View {
        let h = phase ? hi[i] : lo[i]
        let dur = 0.35 + Double(i) * 0.07
        let delay = Double(i) * 0.08
        return Capsule()
            .fill(color)
            .frame(width: 2.5, height: h)
            .animation(
                isAnimating
                    ? Animation.easeInOut(duration: dur).repeatForever(autoreverses: true).delay(delay)
                    : .easeOut(duration: 0.2),
                value: phase
            )
    }
}
