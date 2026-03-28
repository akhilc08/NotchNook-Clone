import SwiftUI
import Combine

struct TimerWidget: View {
    // MARK: - State

    @State private var totalSeconds: Double = 2 * 3600
    @State private var remaining:    Double = 2 * 3600
    @State private var isRunning:    Bool   = false
    @State private var timerSub:     AnyCancellable?
    @State private var doneGlow:     Bool   = false
    @State private var pulseScale:   CGFloat = 1.0

    private let accent = NotchTheme.accent

    private let presets: [(label: String, seconds: Double)] = [
        ("2 hr",    2 * 3600),
        ("1 hr 30", 90 * 60),
        ("1 hr",    3600),
    ]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ringAndTime
                .frame(maxHeight: .infinity)
                .padding(.leading, 4)

            Spacer().frame(width: 20)

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.trailing, 12)
        }
        .padding(.vertical, 10)
        .onDisappear { stopTimer() }
        .onChange(of: remaining) { handleRemainingChange() }
    }

    // MARK: - Ring + Time

    private var ringAndTime: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 3.5)
                .frame(width: 96, height: 96)

            Circle()
                .trim(from: 0, to: remaining <= 0 ? 1.0 : progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accent.opacity(0.3), accent]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 96, height: 96)
                .opacity(doneGlow ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: doneGlow)
                .animation(.linear(duration: 0.5), value: progress)

            if isRunning {
                Circle()
                    .fill(accent)
                    .frame(width: 5, height: 5)
                    .offset(y: -48)
                    .rotationEffect(.degrees(-90 + progress * 360))
                    .animation(.linear(duration: 0.5), value: progress)
                    .shadow(color: accent.opacity(0.9), radius: 5)
            }

            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 15, weight: .light, design: .monospaced))
                    .foregroundStyle(remaining <= 0 ? accent : .white)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 0.5), value: pulseScale)

                Text(stateLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(remaining <= 0
                        ? accent.opacity(0.8)
                        : .white.opacity(NotchTheme.Opacity.tertiary))
                    .kerning(1.8)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 120)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(presets, id: \.label) { preset in
                presetButton(preset)
            }

            Spacer(minLength: 0)

            if remaining <= 0 {
                // Done state: restart CTA
                Button { applyPreset(totalSeconds) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .medium))
                        Text("Start again")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accent.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(accent.opacity(0.35), lineWidth: 0.8)
                            )
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Running state: reset (ghost) + play (dominant)
                HStack(spacing: 10) {
                    Button { resetTimer() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)

                    Button { toggleTimer() } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(accent))
                            .shadow(color: accent.opacity(0.4), radius: 8, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func presetButton(_ preset: (label: String, seconds: Double)) -> some View {
        let active = totalSeconds == preset.seconds
        return Button { applyPreset(preset.seconds) } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(active ? accent : Color.white.opacity(0.18))
                    .frame(width: 5, height: 5)
                Text(preset.label)
                    .font(.system(size: 11, weight: active ? .medium : .regular))
                    .foregroundStyle(active ? .white : .white.opacity(NotchTheme.Opacity.secondary))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(active ? accent.opacity(0.1) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(
                                active ? accent.opacity(0.3) : Color.white.opacity(0.06),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return remaining / totalSeconds
    }

    private var timeString: String {
        let total = Int(max(0, remaining))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private var stateLabel: String {
        if remaining <= 0 { return "Complete" }
        return isRunning ? "Focus" : "Ready"
    }

    // MARK: - Actions

    private func handleRemainingChange() {
        if remaining <= 0 {
            stopTimer()
            doneGlow = true
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        } else if isRunning && remaining < 10 {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
        }
    }

    private func toggleTimer() { isRunning ? stopTimer() : startTimer() }

    private func startTimer() {
        guard remaining > 0 else { return }
        isRunning = true
        pulseScale = 1.0
        timerSub = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remaining > 0 { remaining -= 1 } else { stopTimer() }
            }
    }

    private func stopTimer() {
        isRunning = false
        timerSub?.cancel()
        timerSub = nil
    }

    private func resetTimer() {
        stopTimer()
        doneGlow   = false
        pulseScale = 1.0
        remaining  = totalSeconds
    }

    private func applyPreset(_ seconds: Double) {
        stopTimer()
        doneGlow     = false
        pulseScale   = 1.0
        totalSeconds = seconds
        remaining    = seconds
    }
}
