# NotchNook Clone

A macOS menubar app that lives inside the physical notch of your MacBook. Hover to expand, see your music, calendar, clipboard, and a focus timer — then it retreats. Built with SwiftUI, zero dependencies.

## What it does

**Compact state** — album art thumbnail and an animated audio wave peek out beside the camera. The panel is invisible against the notch.

**Expanded state** — click or hover to open a 500×250 panel that drops down from the notch with a spring animation. Four tabs:

| Tab | Content |
|-----|---------|
| Music | Spotify now playing — album art, track/artist, playback controls, seek bar, volume |
| Calendar | Upcoming events from macOS Calendar |
| Clipboard | Recent clipboard history |
| Productivity | Focus timer |

The accent color across all active UI elements updates live to match the dominant color extracted from the current album art.

## Requirements

- macOS 14 Sonoma or later
- A MacBook with a notch (2021+)
- Spotify (optional — the app still works without it)

## Build & run

```bash
git clone https://github.com/you/NotchNook-Clone
cd NotchNook-Clone
swift run
```

Or build a release binary:

```bash
swift build -c release
.build/release/NotchNook
```

No Xcode required. No dependencies beyond the Swift standard library and system frameworks.

## Permissions

The app needs two permissions on first launch:

- **Automation → Spotify** — to read track info and send playback commands via AppleScript
- **Calendars** — to show upcoming events

macOS will prompt for both.

## Design

Pure black panel on pure black notch — the UI should feel invisible until you need it.

- SF Pro system font throughout, no custom typefaces
- Single blue accent `rgb(77, 115, 209)` that yields to album art color
- Opacity tiers for hierarchy: primary `1.0`, secondary `0.65`, tertiary `0.55`
- Monospaced numerals for all time values
- Dark mode only

## Project structure

```
Sources/NotchNook/
├── AppDelegate.swift           # App entry, menu bar item
├── NotchState.swift            # Global state + theme constants
├── Window/
│   ├── NotchWindowController   # NSPanel setup, notch detection, expand/collapse animation
│   └── NotchHostingView        # NSView subclass for mouse tracking
├── Services/
│   ├── SpotifyService          # AppleScript polling, album art fetch, color extraction
│   ├── CalendarService         # EventKit wrapper
│   └── ClipboardService        # NSPasteboard polling
├── Views/
│   ├── CompactView             # Album art peek + audio wave
│   ├── ExpandedView            # Tab bar + tab content
│   ├── Widgets/                # SpotifyWidget, CalendarWidget, ClipboardWidget, TimerWidget
│   └── Components/             # AlbumArtView, AudioWaveView, MarqueeText, VisualEffectView
└── Models/
    └── SpotifyTrack            # Track data model
```

## How the notch detection works

`NotchWindowController` reads `NSScreen.auxiliaryTopLeftArea` and `auxiliaryTopRightArea` (available macOS 12+) to calculate the exact pixel bounds of the physical notch. The panel is positioned to sit inside those bounds when compact, and drops down from the notch center when expanded. Falls back to a reasonable default for non-notch displays.

## Caveats

- Spotify integration uses AppleScript, which requires the Automation permission and only works with the native Spotify app (not the web player)
- The app polls Spotify every second — negligible CPU, but the polling stops if Spotify isn't running
- External monitor support: the notch panel snaps to the main display; connecting/disconnecting screens is handled via `NSApplication.didChangeScreenParametersNotification`
