import SwiftUI

struct ExpandedView: View {
    @EnvironmentObject private var state:   NotchState
    @EnvironmentObject private var spotify: SpotifyService

    var body: some View {
        NotchTheme.panelColor
            .overlay(
                VStack(spacing: 0) {
                    tabBar
                        .padding(.top, 10)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            )
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(NotchState.Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
    }

    private func tabButton(_ tab: NotchState.Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { state.activeTab = tab }
        } label: {
            Image(systemName: tab.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(state.activeTab == tab
                    ? spotify.dominantColor
                    : .white.opacity(NotchTheme.Opacity.tertiary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tab.accessibilityLabel)
        .accessibilityLabel(tab.accessibilityLabel)
    }

    // MARK: - Content

    @ViewBuilder
    private var tabContent: some View {
        switch state.activeTab {
        case .music:
            SpotifyWidget()
        case .calendar:
            CalendarWidget()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        case .clipboard:
            ClipboardWidget()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        case .productivity:
            TimerWidget()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
    }
}
