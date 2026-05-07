import SwiftUI
import Charts

struct ContentView: View {
    @ObservedObject var monitor: PingMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            stats
            sparkline
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 300)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(monitor.status.color)
                .frame(width: 10, height: 10)
            Text(monitor.status.label)
                .font(.headline)
            Spacer()
            Text(monitor.host)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var stats: some View {
        HStack(spacing: 18) {
            stat("Current", value: monitor.currentLatencyMs.map { "\(Int($0.rounded())) ms" } ?? "—")
            stat("Avg", value: monitor.avgLatencyMs.map { "\(Int($0.rounded())) ms" } ?? "—")
            stat("Loss", value: String(format: "%.0f%%", monitor.packetLossPercent))
        }
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sparkline: some View {
        let samples = Array(monitor.history.enumerated())
        return Chart {
            ForEach(samples, id: \.offset) { idx, result in
                if case .success(let ms) = result {
                    LineMark(
                        x: .value("Sample", idx),
                        y: .value("Latency", ms)
                    )
                    .foregroundStyle(monitor.status.color)
                    .interpolationMethod(.monotone)
                } else {
                    PointMark(
                        x: .value("Sample", idx),
                        y: .value("Latency", 0)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(20)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 70)
    }

    private var footer: some View {
        HStack {
            Text("Pinging every 1s")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
