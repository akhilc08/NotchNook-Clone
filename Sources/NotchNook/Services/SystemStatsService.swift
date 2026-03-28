import Foundation
import Darwin
import SwiftUI

@MainActor
final class SystemStatsService: ObservableObject {
    static let shared = SystemStatsService()

    @Published var cpuUsage:     Double = 0
    @Published var memoryUsage:  Double = 0
    @Published var memoryUsedGB: Double = 0
    @Published var totalMemGB:   Double = 0
    @Published var batteryLevel: Int    = 100
    @Published var isCharging:   Bool   = false

    private var timer: Timer?

    private init() {
        totalMemGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
    }

    func start() {
        Task { await refresh() }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    private func refresh() async {
        let cpu = await Task.detached(priority: .utility) { SystemStatsService.readCPU() }.value
        let (mu, mt) = await Task.detached(priority: .utility) { SystemStatsService.readMemory() }.value
        let (bat, ch) = await Task.detached(priority: .utility) { SystemStatsService.readBattery() }.value

        cpuUsage     = cpu
        memoryUsage  = mt > 0 ? mu / mt : 0
        memoryUsedGB = mu / 1_073_741_824
        batteryLevel = bat
        isCharging   = ch
    }

    // MARK: - CPU

    nonisolated private static func readCPU() -> Double {
        var numCPUs: natural_t = 0
        var info: processor_info_array_t?
        var count: mach_msg_type_number_t = 0
        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &info, &count)
        guard err == KERN_SUCCESS, let info else { return 0 }
        defer {
            vm_deallocate(mach_task_self_,
                          vm_address_t(UInt(bitPattern: info)),
                          vm_size_t(Int(count) * MemoryLayout<Int32>.size))
        }
        var active: Int32 = 0
        var total:  Int32 = 0
        for i in 0..<Int(numCPUs) {
            let b  = i * Int(CPU_STATE_MAX)
            let u  = info[b + Int(CPU_STATE_USER)]
            let s  = info[b + Int(CPU_STATE_SYSTEM)]
            let n  = info[b + Int(CPU_STATE_NICE)]
            let id = info[b + Int(CPU_STATE_IDLE)]
            active += u + s + n
            total  += u + s + n + id
        }
        return total > 0 ? Double(active) / Double(total) : 0
    }

    // MARK: - Memory

    nonisolated private static func readMemory() -> (Double, Double) {
        var stats = vm_statistics64()
        var cnt = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let err = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(cnt)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &cnt)
            }
        }
        guard err == KERN_SUCCESS else { return (0, 0) }
        let ps   = Double(vm_kernel_page_size)
        let used = (Double(stats.active_count) + Double(stats.wire_count) + Double(stats.compressor_page_count)) * ps
        return (used, Double(ProcessInfo.processInfo.physicalMemory))
    }

    // MARK: - Battery (via pmset shell command, avoids IOKit.ps SwiftPM linking issues)

    nonisolated private static func readBattery() -> (Int, Bool) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        proc.arguments = ["-g", "batt"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // e.g. "100%; charging" or "84%; discharging"
        var level = 100
        var charging = false
        for line in out.components(separatedBy: "\n") {
            if let r = line.range(of: #"(\d+)%"#, options: .regularExpression) {
                let s = String(line[r].dropLast()) // remove %
                level = Int(s) ?? 100
            }
            if line.contains("charging") && !line.contains("discharging") { charging = true }
        }
        return (level, charging)
    }
}
