import Foundation

struct SpotifyTrack: Equatable {
    let id: String
    let name: String
    let artist: String
    let album: String
    let artworkURL: String
    var duration: Double   // seconds
    var position: Double   // seconds
    var isPlaying: Bool
}
