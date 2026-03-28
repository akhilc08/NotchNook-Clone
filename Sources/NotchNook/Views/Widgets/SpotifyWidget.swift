import SwiftUI

struct SpotifyWidget: View {
    @EnvironmentObject private var spotify: SpotifyService
    @State private var dragging = false
    @State private var dragPos: Double = 0

    var body: some View {
        if let track = spotify.currentTrack {
            GeometryReader { geo in
                nowPlaying(track, geo: geo)
            }
        } else {
            notPlaying
        }
    }

    // MARK: - Now Playing

    private func nowPlaying(_ track: SpotifyTrack, geo: GeometryProxy) -> some View {
        let artSize = geo.size.height

        return HStack(spacing: 0) {
            // ── Album art: full-bleed left, no corner radius ──
            Group {
                if let img = spotify.albumArt {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.black
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: artSize * 0.28))
                                .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost))
                        )
                }
            }
            .frame(width: artSize, height: artSize)
            .clipped()
            .accessibilityLabel("Album art")

            // ── Right panel: track info + seek + controls ──
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 4) {
                    MarqueeText(
                        text: track.name,
                        font: .system(size: 13, weight: .semibold),
                        color: .white
                    )
                    .frame(height: 18)

                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(NotchTheme.Opacity.secondary))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 10)

                seekBar(track)

                controls
                    .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(NotchTheme.panelColor)
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .background(NotchTheme.panelColor)
    }

    // MARK: - Seek Bar

    private func seekBar(_ track: SpotifyTrack) -> some View {
        let pos = dragging ? dragPos : spotify.playerPosition
        let dur = track.duration > 0 ? track.duration : 1

        return VStack(spacing: 5) {
            GeometryReader { geo in
                let w    = geo.size.width
                let frac = max(0, min(1, pos / dur))
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear).frame(width: w)
                    Capsule().fill(Color.white.opacity(0.1)).frame(width: w, height: 3)
                    Capsule().fill(spotify.dominantColor.opacity(0.85)).frame(width: w * frac, height: 3)
                }
                .frame(width: w, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragging = true
                        dragPos  = max(0, min(dur, (v.location.x / w) * dur))
                    }
                    .onEnded { _ in
                        spotify.seek(to: dragPos)
                        dragging = false
                    }
                )
            }
            .frame(height: 32)
            .accessibilityLabel("Seek position")
            .accessibilityValue(fmt(pos))

            HStack {
                Text(fmt(pos))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
                Spacer()
                Text(fmt(dur))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 0) {
            ctrlBtn("backward.fill", size: 14, label: "Previous track") { spotify.prevTrack() }
            Spacer()
            ctrlBtn(
                spotify.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                size: 28,
                tint: .white,
                label: spotify.isPlaying ? "Pause" : "Play"
            ) { spotify.playPause() }
            Spacer()
            ctrlBtn("forward.fill", size: 14, label: "Next track") { spotify.nextTrack() }
            Spacer()
            Image(systemName: "speaker.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost))
                .accessibilityHidden(true)
            Slider(value: Binding(
                get: { spotify.volume },
                set: { spotify.setVolume($0) }
            ), in: 0...100)
            .frame(width: 60)
            .tint(spotify.dominantColor.opacity(0.6))
            .accessibilityLabel("Volume")
        }
    }

    private func ctrlBtn(
        _ sym: String,
        size: CGFloat,
        tint: Color = Color.white.opacity(0.75),
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        CtrlButton(symbol: sym, size: size, tint: tint, label: label, action: action)
    }

    // MARK: - Not Playing

    private var notPlaying: some View {
        VStack(spacing: 10) {
            Image(systemName: spotify.isSpotifyRunning ? "music.note.list" : "music.note")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost))
                .accessibilityHidden(true)
            Text(spotify.isSpotifyRunning ? "Nothing playing" : "Spotify not running")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            if !spotify.isSpotifyRunning {
                Button("Open Spotify") {
                    NSWorkspace.shared.launchApplication("Spotify")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.07))
                .clipShape(Capsule())
                .accessibilityLabel("Open Spotify")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NotchTheme.panelColor)
    }

    private func fmt(_ s: Double) -> String {
        let t = Int(max(0, s))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

private struct CtrlButton: View {
    let symbol: String
    let size: CGFloat
    let tint: Color
    let label: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(hovered ? tint.opacity(1.0) : tint)
                .frame(minWidth: 28, minHeight: 28)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovered ? 1.18 : 1.0)
        .animation(.easeOut(duration: 0.12), value: hovered)
        .onHover { hovered = $0 }
        .accessibilityLabel(label)
    }
}
