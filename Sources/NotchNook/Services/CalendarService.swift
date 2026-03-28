import EventKit
import SwiftUI
import Foundation

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var authStatus: EKAuthorizationStatus = .notDetermined

    private let store = EKEventStore()
    private var refreshTimer: Timer?

    private init() {
        authStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func start() {
        let current = EKEventStore.authorizationStatus(for: .event)
        if current == .authorized || (current.rawValue == 3) /* fullAccess on macOS 14 */ {
            authStatus = current
            startRefreshing()
            return
        }
        if current == .notDetermined {
            requestAccess()
        } else {
            authStatus = current
        }
    }

    private func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                Task { @MainActor [weak self] in
                    self?.authStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted { self?.startRefreshing() }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                Task { @MainActor [weak self] in
                    self?.authStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted { self?.startRefreshing() }
                }
            }
        }
    }

    private func startRefreshing() {
        fetchEvents()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.fetchEvents() }
        }
    }

    func fetchEvents() {
        let now    = Date()
        let end    = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let pred   = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: pred)
            .sorted { $0.startDate < $1.startDate }
            .prefix(6)
            .map(CalendarEvent.init)
        upcomingEvents = Array(events)
    }
}

// MARK: - Model

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: Color

    init(from event: EKEvent) {
        id         = event.eventIdentifier ?? UUID().uuidString
        title      = event.title ?? "Untitled"
        startDate  = event.startDate
        endDate    = event.endDate
        isAllDay   = event.isAllDay
        calendarColor = event.calendar.cgColor.map { Color(cgColor: $0) } ?? .blue
    }

    var timeString: String {
        if isAllDay { return "All Day" }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: startDate)
    }

    var relativeLabel: String {
        let diff = startDate.timeIntervalSinceNow
        if diff < 0  { return "Now" }
        if diff < 60 { return "In \(Int(diff))s" }
        if diff < 3600 { return "In \(Int(diff / 60))m" }
        if diff < 86400 { return "In \(Int(diff / 3600))h" }
        return timeString
    }
}
