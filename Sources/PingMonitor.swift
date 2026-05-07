import Foundation
import SwiftUI
import Combine

enum PingResult: Equatable {
    case success(latencyMs: Double)
    case timeout
}

enum PingStatus {
    case unknown, good, slow, degraded, down

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .good:    return .green
        case .slow:    return .yellow
        case .degraded: return .orange
        case .down:    return .red
        }
    }

    var label: String {
        switch self {
        case .unknown:  return "Starting…"
        case .good:     return "Good"
        case .slow:     return "Slow"
        case .degraded: return "Degraded"
        case .down:     return "Down"
        }
    }
}

@MainActor
final class PingMonitor: ObservableObject {
    @Published private(set) var currentLatencyMs: Double? = nil
    @Published private(set) var status: PingStatus = .unknown
    @Published private(set) var history: [PingResult] = []
    @Published private(set) var packetLossPercent: Double = 0
    @Published private(set) var avgLatencyMs: Double? = nil

    let host: String
    private let historyLimit = 60
    private var timerTask: Task<Void, Never>?

    init(host: String = "8.8.8.8") {
        self.host = host
        start()
    }

    deinit {
        timerTask?.cancel()
    }

    func start() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.performPing()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func performPing() async {
        let result = await Self.runPing(host: host)
        record(result)
    }

    private static func runPing(host: String) async -> PingResult {
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/sbin/ping")
            process.arguments = ["-c", "1", "-W", "2000", host]

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                return .timeout
            }

            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if let range = output.range(of: #"time=([0-9.]+)\s*ms"#, options: .regularExpression) {
                let match = output[range]
                let numberRange = match.range(of: #"[0-9.]+"#, options: .regularExpression)!
                if let ms = Double(match[numberRange]) {
                    return .success(latencyMs: ms)
                }
            }
            return .timeout
        }.value
    }

    private func record(_ result: PingResult) {
        history.append(result)
        if history.count > historyLimit { history.removeFirst() }

        if case .success(let ms) = result {
            currentLatencyMs = ms
        } else {
            currentLatencyMs = nil
        }

        let timeoutCount = history.reduce(0) { $0 + ($1 == .timeout ? 1 : 0) }
        packetLossPercent = Double(timeoutCount) / Double(history.count) * 100

        let latencies: [Double] = history.compactMap {
            if case .success(let ms) = $0 { return ms } else { return nil }
        }
        avgLatencyMs = latencies.isEmpty ? nil : latencies.reduce(0, +) / Double(latencies.count)

        updateStatus()
    }

    private func updateStatus() {
        let recent = Array(history.suffix(10))
        guard !recent.isEmpty else { status = .unknown; return }

        let recentTimeouts = recent.reduce(0) { $0 + ($1 == .timeout ? 1 : 0) }
        let recentLatencies: [Double] = recent.compactMap {
            if case .success(let ms) = $0 { return ms } else { return nil }
        }
        let avgRecent = recentLatencies.isEmpty
            ? Double.infinity
            : recentLatencies.reduce(0, +) / Double(recentLatencies.count)

        if recentTimeouts >= 5 {
            status = .down
        } else if recentTimeouts >= 2 || avgRecent > 300 {
            status = .degraded
        } else if avgRecent > 100 {
            status = .slow
        } else {
            status = .good
        }
    }
}
