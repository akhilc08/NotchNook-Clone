import SwiftUI

struct AlbumArtView: View {
    @EnvironmentObject private var spotify: SpotifyService
    let size: CGFloat
    var cornerFraction: CGFloat = 0.12

    var body: some View {
        Group {
            if let img = spotify.albumArt {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.08)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.38))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * cornerFraction, style: .continuous))
    }
}
