//
//  BatchClient.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import Foundation

public struct BatchClient: Sendable {
    public var start: @Sendable () -> Void
    public var stop: @Sendable () -> Void
    public var stream: @Sendable () -> AsyncStream<RawDataBatch>
}

extension BatchClient {
    public static func live(buffer: SampleBuffer) -> Self {
        let actor = BatchActor(buffer: buffer)

        return Self(
            start: {
                Task { await actor.start() }
            },
            stop: {
                Task { await actor.stop() }
            },
            stream: {
                AsyncStream(RawDataBatch.self) { continuation in
                    Task { await actor.setContinuation(continuation) }

                    continuation.onTermination = { _ in
                        Task { await actor.finish() }
                    }
                }
            }
        )
    }

    actor BatchActor {
        private let buffer: SampleBuffer
        private var continuation: AsyncStream<RawDataBatch>.Continuation?
        private var task: Task<Void, Never>?

        init(buffer: SampleBuffer) {
            self.buffer = buffer
        }

        func setContinuation(_ newContinuation: AsyncStream<RawDataBatch>.Continuation) {
            continuation = newContinuation
        }

        func finish() {
            continuation?.finish()
        }

        func start() {
            task?.cancel()

            task = Task {
                do {
                    while true {
                        try Task.checkCancellation()
                        try await Task.sleep(for: .seconds(Constants.batchSizeInSeconds))

                        let samples = await buffer.flush()
                        let filtered = await filterSamples(samples, threshold: Constants.rawDataThreshold)

                        let batch = RawDataBatch(
                            collectedAt: Date().timeIntervalSince1970,
                            samples: filtered
                        )

                        continuation?.yield(batch)
                    }
                } catch { /* its just for the CancellationError, in our case, no need to handle it */}
            }
        }

        func stop() {
            task?.cancel()
            task = nil
        }

        // MARK: - Simple filtering to get rid of data from idling phone
        private func filterSamples(
            _ samples: [RawDataSample],
            threshold: Float
        ) -> [RawDataSample] {
            guard !samples.isEmpty else { return [] }

            var filtered: [RawDataSample] = []

            for sample in samples {
                guard let previous = filtered.last else {
                    filtered.append(sample) // keep the last one, so every `Constants.batchSizeInSeconds` we have some value there
                    continue
                }

                if hasSignificantChange(from: previous, to: sample, threshold: threshold) {
                    filtered.append(sample)
                }
            }

            return filtered
        }

        private func hasSignificantChange(
            from a: RawDataSample,
            to b: RawDataSample,
            threshold: Float
        ) -> Bool {
            abs(a.x - b.x) > threshold ||
            abs(a.y - b.y) > threshold ||
            abs(a.z - b.z) > threshold
        }
    }
}
