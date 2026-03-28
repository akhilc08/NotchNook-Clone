import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var expandOnHover = true

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.black)
                            .frame(width: 44, height: 44)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NotchNook")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Version 1.0  •  Your notch, elevated")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                }
                .padding(20)

                Divider().background(Color.white.opacity(0.1))

                // Options
                ScrollView {
                    VStack(spacing: 1) {
                        settingsSection("General") {
                            settingsRow(title: "Launch at login", icon: "power") {
                                Toggle("", isOn: $launchAtLogin)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .onChange(of: launchAtLogin) { val in
                                        if #available(macOS 13.0, *) {
                                            if val { try? SMAppService.mainApp.register() }
                                            else   { try? SMAppService.mainApp.unregister() }
                                        }
                                    }
                            }
                            settingsRow(title: "Expand on hover", icon: "arrow.up.left.and.arrow.down.right") {
                                Toggle("", isOn: $expandOnHover)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                        }

                        settingsSection("Permissions") {
                            settingsRow(title: "Calendar access", icon: "calendar") {
                                Button("Open Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            }
                            settingsRow(title: "Spotify automation", icon: "music.note") {
                                Button("Open Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 440, height: 380)
        .onAppear {
            if #available(macOS 13.0, *) {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)
            content()
        }
    }

    private func settingsRow<Trailing: View>(title: String, icon: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
