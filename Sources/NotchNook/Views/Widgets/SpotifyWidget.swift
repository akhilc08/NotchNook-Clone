import SwiftUI

struct SpotifyWidget: View {
    @EnvironmentObject private var spotify: SpotifyService
    @State private var dragging = false
    @State private var dragPos: Double = 0

    var body: some View {
        if let track = spotify.currentTrack {
            nowPlaying(track)
        } else {
            notPlaying
        }
    }

    // MARK: - Now Playing

    private func nowPlaying(_ track: SpotifyTrack) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                // Album art
                AlbumArtView(size: 96)
                    .shadow(color: spotify.dominantColor.opacity(0.5), radius: 14, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)

                    Text(track.album)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    // Seek bar
                    seekBar(track)

                    // Transport controls
                    controls
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Seek Bar

    private func seekBar(_ track: SpotifyTrack) -> some View {
        let pos = dragging ? dragPos : track.position
        let dur = track.duration > 0 ? track.duration : 1

        return VStack(spacing: 3) {
            GeometryReader { geo in
                let w = geo.size.width
                let frac = max(0, min(1, pos / dur))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                    Capsule()
                        .fill(spotify.dominantColor)
                        .frame(width: w * frac, height: 3)
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .offset(x: w * frac - 5)
                }
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
            .frame(height: 10)

            HStack {
                Text(fmt(pos))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text(fmt(dur))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 18) {
            ctrlBtn("backward.fill", size: 14) { spotify.prevTrack() }
            ctrlBtn(spotify.isPlaying ? "pause.circle.fill" : "play.circle.fill", size: 26, tint: spotify.dominantColor) {
                spotify.playPause()
            }
            ctrlBtn("forward.fill", size: 14) { spotify.nextTrack() }

            Spacer()

            Image(systemName: "speaker.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.35))
            Slider(value: Binding(
                get: { spotify.volume },
                set: { spotify.setVolume($0); spotify.volume = $0 }
            ), in: 0...100)
            .frame(width: 62)
            .tint(spotify.dominantColor)
        }
    }

    private func ctrlBtn(_ sym: String, size: CGFloat, tint: Color = Color.white.opacity(0.85), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: sym)
                .font(.system(size: size))
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Not Playing

    private var notPlaying: some View {
        VStack(spacing: 10) {
            Image(systemName: spotify.isSpotifyRunning ? "music.note.list" : "music.note")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.25))
            Text(spotify.isSpotifyRunning ? "Nothing playing" : "Spotify not running")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
            if !spotify.isSpotifyRunning {
                Button("Open Spotify") {
                    NSWorkspace.shared.launchApplication("Spotify")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fmt(_ s: Double) -> String {
        let t = Int(max(0, s))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
