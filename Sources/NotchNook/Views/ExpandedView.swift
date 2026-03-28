import SwiftUI

/// Full panel shown below the notch when expanded.
struct ExpandedView: View {
    @EnvironmentObject private var state:   NotchState
    @EnvironmentObject private var spotify: SpotifyService

    var body: some View {
        ZStack {
            // Frosted glass base
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            // Album-art colour tint
            spotify.dominantColor.opacity(0.07)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius:     0,
                bottomLeadingRadius:  20,
                bottomTrailingRadius: 20,
                topTrailingRadius:    0,
                style: .continuous
            )
        )
        .overlay(
            VStack(spacing: 0) {
                tabBar
                    .padding(.top, 10)
                    .padding(.horizontal, 14)

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                tabContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
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
                .foregroundStyle(state.activeTab == tab ? .white : .white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(state.activeTab == tab
                              ? Color.white.opacity(0.12)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var tabContent: some View {
        switch state.activeTab {
        case .music:     SpotifyWidget()
        case .calendar:  CalendarWidget()
        case .stats:     SystemStatsWidget()
        case .clipboard: ClipboardWidget()
        }
    }
}
