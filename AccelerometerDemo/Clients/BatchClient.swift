//
//  BatchMakerClient.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import Foundation

public struct BatchMakerClient: Sendable {
    public var start: @Sendable () -> Void
    public var stop: @Sendable () -> Void
    public var stream: @Sendable () -> AsyncStream<AccelerometerBatch>
}

extension BatchMakerClient {
    public static func live(buffer: SampleBuffer) -> Self {
        let actor = BatchMakerActor(buffer: buffer)

        return Self(
            start: {
                Task { await actor.start() }
            },
            stop: {
                Task { await actor.stop() }
            },
            stream: {
                AsyncStream(AccelerometerBatch.self) { continuation in
                    Task { await actor.setContinuation(continuation) }

                    continuation.onTermination = { _ in
                        Task { await actor.finish() }
                    }
                }
            }
        )
    }

    actor BatchMakerActor {
        private let buffer: SampleBuffer
        private var continuation: AsyncStream<AccelerometerBatch>.Continuation?
        private var task: Task<Void, Never>?

        init(buffer: SampleBuffer) {
            self.buffer = buffer
        }

        func setContinuation(_ newContinuation: AsyncStream<AccelerometerBatch>.Continuation) {
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
                        try await Task.sleep(for: .seconds(5))

                        let samples = await buffer.flush()

                        let batch = AccelerometerBatch(
                            collectedAt: Date().timeIntervalSince1970,
                            samples: samples
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
    }
}
