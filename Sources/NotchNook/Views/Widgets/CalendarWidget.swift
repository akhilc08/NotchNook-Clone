import SwiftUI
import EventKit

struct CalendarWidget: View {
    @EnvironmentObject private var cal: CalendarService

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
                            .foregroundStyle(.green.opacity(0.7))
                        Text("All clear today")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
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

            VStack(alignment: .leading, spacing: 2) {
                Text(e.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(e.relativeLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(e.timeString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Permission views

    private var requestView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(0.3))
            Text("Calendar access needed")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
            Button("Grant Access") { CalendarService.shared.start() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.blue)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(0.3))
            Text("Calendar access denied")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.blue)
        }
    }
}
