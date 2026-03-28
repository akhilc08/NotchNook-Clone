import SwiftUI
import EventKit

struct CalendarWidget: View {
    @EnvironmentObject private var cal:     CalendarService
    @EnvironmentObject private var spotify: SpotifyService

    var body: some View {
        let status = cal.authStatus
        // .authorized = 3, .fullAccess is macOS 14; treat both as granted
        let granted = status == .authorized || status.rawValue == 3
        let denied  = status == .denied || status == .restricted

        Group {
            if granted {
                eventsList
            } else if denied {
                deniedView
            } else {
                requestView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Events

    private var eventsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 5) {
                if cal.upcomingEvents.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(spotify.dominantColor.opacity(0.7))
                            .accessibilityHidden(true)
                        Text("All clear today")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                } else {
                    ForEach(cal.upcomingEvents) { event in
                        eventRow(event)
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private func eventRow(_ e: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(e.calendarColor)
                .frame(width: 3, height: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(e.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(e.relativeLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(e.timeString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(e.title), \(e.relativeLabel), \(e.timeString)")
    }

    // MARK: - Permission views

    private var requestView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost + 0.1))
                .accessibilityHidden(true)
            Text("Calendar access needed")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            Button("Grant Access") { CalendarService.shared.start() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(spotify.dominantColor)
                .accessibilityLabel("Grant calendar access")
        }
    }

    private var deniedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost + 0.1))
                .accessibilityHidden(true)
            Text("Calendar access denied")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(spotify.dominantColor)
            .accessibilityLabel("Open System Settings for calendar permissions")
        }
    }
}
