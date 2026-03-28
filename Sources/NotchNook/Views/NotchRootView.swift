import SwiftUI

/// Root view that fills the NSPanel.
/// In compact state the window is ~37 pt tall — only CompactView shows.
/// In expanded state the window grows down, revealing ExpandedView beneath.
struct NotchRootView: View {
    @EnvironmentObject private var state: NotchState

    var body: some View {
        VStack(spacing: 0) {
            // Compact strip — always at the top of the window
            CompactView()
                .frame(height: 37)

            // Expanded panel — clipped by the window frame when collapsed
            ExpandedView()
        }
        .background(Color.black)
    }
}
