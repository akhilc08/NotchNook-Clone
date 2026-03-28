import AppKit
import SwiftUI

@MainActor
final class SpotifyService: ObservableObject {
    static let shared = SpotifyService()

    @Published var currentTrack:     SpotifyTrack? = nil
    @Published var isPlaying:        Bool          = false
    @Published var playerPosition:   Double        = 0
    @Published var albumArt:         NSImage?      = nil
    @Published var dominantColor:    Color         = Color(red: 0.2, green: 0.55, blue: 1.0)
    @Published var isSpotifyRunning: Bool          = false
    @Published var volume:           Double        = 80

    private var pollTimer: Timer?
    private var lastTrackID = ""
    private var artCache: [String: NSImage] = [:]

    private init() {}

    func startMonitoring() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.poll() }
        }
        Task { await poll() }
    }

    private func poll() async {
        let raw = await Task.detached(priority: .utility) { SpotifyService.runScript() }.value
        applyRaw(raw)
    }

    // MARK: - AppleScript (nonisolated so it can run off main actor)

    nonisolated private static func runScript() -> String {
        let src = """
        if application "Spotify" is running then
            tell application "Spotify"
                set ps to player state
                if ps is playing or ps is paused then
                    set t to current track
                    return "OK|" & (id of t) & "|" & (name of t) & "|" & (artist of t) & "|" & (album of t) & "|" & (artwork url of t) & "|" & ((duration of t) as text) & "|" & (player position as text) & "|" & (sound volume as text) & "|" & ((ps is playing) as text)
                end if
                return "STOPPED"
            end tell
        end if
        return "NOT_RUNNING"
        """
        var err: NSDictionary?
        return NSAppleScript(source: src)?.executeAndReturnError(&err).stringValue ?? "NOT_RUNNING"
    }

    private func applyRaw(_ raw: String) {
        switch raw {
        case "NOT_RUNNING":
            isSpotifyRunning = false
            isPlaying = false
            return
        case "STOPPED":
            isSpotifyRunning = true
            isPlaying = false
            currentTrack = nil
            return
        default: break
        }

        isSpotifyRunning = true
        let p = raw.components(separatedBy: "|")
        guard p.count >= 10 else { isPlaying = false; return }

        let trackID  = p[1]
        let dur      = (Double(p[6]) ?? 0) / 1000.0
        let pos      = Double(p[7]) ?? 0
        let vol      = Double(p[8]) ?? 80
        let playing  = p[9].trimmingCharacters(in: .whitespacesAndNewlines) == "true"

        isPlaying      = playing
        playerPosition = pos
        volume         = vol

        if trackID != lastTrackID {
            lastTrackID  = trackID
            currentTrack = SpotifyTrack(id: trackID, name: p[2], artist: p[3],
                                        album: p[4], artworkURL: p[5],
                                        duration: dur, position: pos, isPlaying: playing)
            loadArt(url: p[5])
        }
    }

    private func loadArt(url: String) {
        if let cached = artCache[url] { albumArt = cached; tintFrom(cached); return }
        guard let u = URL(string: url) else { return }
        URLSession.shared.dataTask(with: u) { [weak self] data, _, _ in
            guard let data, let img = NSImage(data: data) else { return }
            Task { @MainActor [weak self] in
                self?.artCache[url] = img
                self?.albumArt = img
                self?.tintFrom(img)
            }
        }.resume()
    }

    private func tintFrom(_ img: NSImage) {
        Task.detached(priority: .utility) {
            let c = img.dominantColor()
            await MainActor.run { self.dominantColor = c }
        }
    }

    // MARK: - Controls

    func playPause()  { send("playpause");     refresh(after: 0.25) }
    func nextTrack()  { send("next track");    refresh(after: 0.4)  }
    func prevTrack()  { send("previous track"); refresh(after: 0.4) }

    func setVolume(_ v: Double) {
        send("set sound volume to \(Int(v))")
    }

    func seek(to pos: Double) {
        send("set player position to \(pos)")
    }

    private func send(_ cmd: String) {
        Task.detached(priority: .userInteractive) {
            var e: NSDictionary?
            NSAppleScript(source: "tell application \"Spotify\" to \(cmd)")?.executeAndReturnError(&e)
        }
    }

    private func refresh(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Task { await self.poll() }
        }
    }
}
