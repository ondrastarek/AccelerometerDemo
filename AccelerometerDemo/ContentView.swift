//
//  ContentView.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//


import SwiftUI

struct ContentView: View {
    let accelerometer: AccelerometerClient
    let networkService = NetworkService()

    @State private var isRunning = false
    @State private var lines: [String] = []

    private let maxLines = Constants.maxLinesInUI

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
                }
            }

            Spacer()
        }
        .padding()
    }

    private func start() {
        isRunning = true
        lines.removeAll()

        Task {
            accelerometer.start()

            for await batch in accelerometer.stream() {

                // HERE IS THE BE SENDING
                //try await networkService.send(batch)

                await MainActor.run {
                    for s in batch.samples {
                        lines.append("x: \(s.x), y: \(s.y), z: \(s.z)")
                        if lines.count > maxLines { lines.removeFirst() }
                    }
                }
            }
        }
    }

    private func stop() {
        isRunning = false
        accelerometer.stop()
    }
}
