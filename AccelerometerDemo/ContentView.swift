import SwiftUI

struct ContentView: View {
    let accelerometer: AccelerometerClient
    let buffer: SampleBuffer
    let batchMaker: BatchClient

    @State private var sampleTask: Task<Void, Never>?
    @State private var batchTask: Task<Void, Never>?
    @State private var isRunning = false

    @State private var lines: [String] = []

    private let maxLines = 20

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button("Start") {
                    start()
                }
                .disabled(isRunning)

                Button("Stop") {
                    stop()
                }
                .disabled(!isRunning)
            }

            Text(isRunning ? "Collecting data…" : "Stopped")
                .font(.headline)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines.indices, id: \.self) { idx in
                    Text(lines[idx])
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Control

    private func start() {
        guard !isRunning else { return }
        isRunning = true
        lines.removeAll()

        // 1) Accelerometer → buffer
        sampleTask = Task {
            guard accelerometer.isAccelerometerAvailable() else {
                await MainActor.run {
                    lines.append("Accelerometer not available")
                    trimLines()
                    isRunning = false
                }
                return
            }

            accelerometer.start()

            for await sample in accelerometer.stream() {
                await buffer.append(sample)
            }
        }

        // 2) BatchMaker → show last samples
        batchTask = Task {
            batchMaker.start()

            for await batch in batchMaker.stream() {
                do {
                    let _ = try JSONEncoder().encode(batch) // “prepare for sending”

                    let newLines = batch.samples.map { sample in
                        "x: \(sample.x), y: \(sample.y), z: \(sample.z)"
                    }

                    await MainActor.run {
                        lines.append(contentsOf: newLines)
                        trimLines()
                    }
                } catch {
                    await MainActor.run {
                        lines.append("Encoding error: \(error.localizedDescription)")
                        trimLines()
                    }
                }
            }
        }
    }

    private func stop() {
        guard isRunning else { return }
        isRunning = false

        accelerometer.stop()
        batchMaker.stop()

        sampleTask?.cancel()
        batchTask?.cancel()

        sampleTask = nil
        batchTask = nil
    }

    @MainActor
    private func trimLines() {
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }
}