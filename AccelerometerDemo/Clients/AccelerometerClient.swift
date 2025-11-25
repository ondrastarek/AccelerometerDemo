//
//  AccelerometerClient.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//


public struct AccelerometerClient: Sendable {
    public var start: @Sendable () -> Void
    public var stop: @Sendable () -> Void
    public var stream: @Sendable () -> AsyncStream<RawDataBatch>
}

extension AccelerometerClient {
    public static let live = {
        let rawDataClient = RawDataClient.live
        let buffer = SampleBuffer()
        let batchClient = BatchClient.live(buffer: buffer)

        let pipeline = MotionPipelineActor(
            rawDataClient: rawDataClient,
            buffer: buffer,
            batchClient: batchClient
        )

        return Self(
            start: {
                Task { await pipeline.start() }
            },
            stop: {
                Task { await pipeline.stop() }
            },
            stream: {
                AsyncStream(RawDataBatch.self) { continuation in
                    Task { await pipeline.setContinuation(continuation) }
                    continuation.onTermination = { _ in
                        Task { await pipeline.finish() }
                    }
                }
            }
        )
    }()
}

private actor MotionPipelineActor {
    private let rawDataClient: RawDataClient
    private let buffer: SampleBuffer
    private let batchClient: BatchClient

    private var continuation: AsyncStream<RawDataBatch>.Continuation?

    init(
        rawDataClient: RawDataClient,
        buffer: SampleBuffer,
        batchClient: BatchClient
    ) {
        self.rawDataClient = rawDataClient
        self.buffer = buffer
        self.batchClient = batchClient
    }

    func setContinuation(_ newContinuation: AsyncStream<RawDataBatch>.Continuation) {
        continuation = newContinuation
    }

    func finish() {
        continuation?.finish()
    }

    func start() {
        stop()

        Task {
            guard await rawDataClient.isAccelerometerAvailable() else { return }

            rawDataClient.start()

            for await sample in rawDataClient.stream() {
                await buffer.append(sample)
            }
        }

        Task {
            batchClient.start()

            for await batch in batchClient.stream() {
                continuation?.yield(batch)
            }
        }
    }

    func stop() {
        rawDataClient.stop()
        batchClient.stop()
    }
}
