import SwiftUI

struct SystemStatsWidget: View {
    @EnvironmentObject private var stats: SystemStatsService

    var body: some View {
        VStack(spacing: 16) {
            statRow(
                label: "CPU",
                icon: "cpu",
                value: stats.cpuUsage,
                color: cpuColor,
                detail: "\(Int(stats.cpuUsage * 100))%"
            )
            statRow(
                label: "Memory",
                icon: "memorychip",
                value: stats.memoryUsage,
                color: .blue,
                detail: String(format: "%.1f / %.0f GB", stats.memoryUsedGB, stats.totalMemGB)
            )
            batteryRow
        }
        .padding(.top, 10)
    }

    // MARK: - Rows

    private func statRow(label: String, icon: String, value: Double, color: Color, detail: String) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color.opacity(0.8))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 5)
                        .animation(.easeOut(duration: 0.6), value: value)
                }
            }
            .frame(height: 5)
        }
    }

    private var batteryRow: some View {
        HStack(spacing: 14) {
            Image(systemName: batteryIcon)
                .font(.system(size: 20))
                .foregroundStyle(batteryColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Battery")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Text(stats.isCharging ? "Charging" : "\(stats.batteryLevel)% remaining")
                    .font(.system(size: 10))
                    .foregroundStyle(batteryColor)
            }

            Spacer()

            Text("\(stats.batteryLevel)%")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(batteryColor)
        }
    }

    // MARK: - Computed colors / icons

    private var cpuColor: Color {
        switch stats.cpuUsage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }

    private var batteryColor: Color {
        if stats.isCharging { return .green }
        switch stats.batteryLevel {
        case 20...: return .white
        case 10..<20: return .yellow
        default: return .red
        }
    }

    private var batteryIcon: String {
        if stats.isCharging { return "battery.100percent.bolt" }
        switch stats.batteryLevel {
        case 75...: return "battery.100percent"
        case 50..<75: return "battery.75percent"
        case 25..<50: return "battery.50percent"
        case 10..<25: return "battery.25percent"
        default: return "battery.0percent"
        }
    }
}
