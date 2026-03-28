import SwiftUI

struct ClipboardWidget: View {
    @EnvironmentObject private var clipboard: ClipboardService
    @State private var hoveredID: String? = nil


    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                if clipboard.history.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(NotchTheme.Opacity.ghost))
                            .accessibilityHidden(true)
                        Text("Nothing copied yet")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                } else {
                    ForEach(clipboard.history) { item in
                        itemRow(item)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func itemRow(_ item: ClipboardItem) -> some View {
        Button {
            clipboard.copy(item)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.isImage ? "photo" : "doc.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
                    .frame(width: 14)
                    .accessibilityHidden(true)

                Text(item.preview)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.timestamp, style: .relative)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(NotchTheme.Opacity.tertiary))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(hoveredID == item.id ? 0.1 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hov in hoveredID = hov ? item.id : nil }
        .accessibilityLabel("Copy: \(item.preview)")
    }
}
