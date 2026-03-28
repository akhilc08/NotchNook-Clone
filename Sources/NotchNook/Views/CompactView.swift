import SwiftUI

/// Always-visible strip that sits in the physical notch.
struct CompactView: View {
    @EnvironmentObject private var spotify: SpotifyService

    var body: some View {
        HStack(spacing: 8) {
            // Album art thumbnail
            AlbumArtView(size: 22, cornerFraction: 0.2)
                .opacity(spotify.currentTrack != nil ? 1 : 0)

            // Track info – marquee scrolling
            if let track = spotify.currentTrack {
                MarqueeText(
                    text: "\(track.name)  —  \(track.artist)",
                    font: .system(size: 10, weight: .medium),
                    color: .white
                )
            } else {
                Text("NotchNook")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity)
            }

            // Equalizer or static icon
            if spotify.isPlaying {
                AudioWaveView(color: .green, isAnimating: true)
                    .frame(width: 18, height: 16)
            } else if spotify.currentTrack != nil {
                Image(systemName: "pause.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
