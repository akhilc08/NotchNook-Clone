import SwiftUI

/// Always-visible strip that sits in the physical notch.
/// When expanded: pure black to bridge the notch to the panel.
/// When compact: album art (left edge) + wave (right edge) peek out beside the notch camera.
struct CompactView: View {
    @EnvironmentObject private var state:  NotchState
    @EnvironmentObject private var spotify: SpotifyService

    var body: some View {
        ZStack {
            Color.black

            if !state.isExpanded {
                HStack {
                    AlbumArtView(size: 20, cornerFraction: 0.2)
                        .opacity(spotify.currentTrack != nil ? 1 : 0)
                    Spacer()
                    if spotify.isPlaying {
                        AudioWaveView(color: spotify.dominantColor, isAnimating: true)
                            .frame(width: 16, height: 14)
                    } else if spotify.currentTrack != nil {
                        // play.fill = "tap to resume" — indicates paused state
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
