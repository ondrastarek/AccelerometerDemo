//
//  RawDataClient.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import CoreMotion
import Foundation

public struct RawDataClient: Sendable {
    public var isAccelerometerAvailable: () -> Bool
    public var start: @Sendable () -> Void
    public var stop: @Sendable () -> Void
    public var stream: @Sendable () -> AsyncStream<RawDataSample>
}

extension RawDataClient {
    public static let live = {
        let continuationActor = ContinuationActor()
        let motionManager = CMMotionManager()
        let updateInterval = Constants.accelerometerFrequencyInHz

        return Self(
            isAccelerometerAvailable: {
                motionManager.isAccelerometerAvailable
            },

            start: {
                motionManager.accelerometerUpdateInterval = updateInterval
                motionManager.startAccelerometerUpdates(to: OperationQueue()) { data, error in
                    if let error = error {
                        print("CM error: \(error)")
                        Task { await continuationActor.finish() }
                        return
                    }

                    guard let data else { return }

                    let sample = RawDataSample(
                        timestamp: data.timestamp,
                        x: Float((data.acceleration.x * 100).rounded() / 100), // two decimals
                        y: Float((data.acceleration.y * 100).rounded() / 100),
                        z: Float((data.acceleration.z * 100).rounded() / 100)
                    )

                    Task {
                        await continuationActor.yield(sample)
                    }
                }
            },

            stop: {
                motionManager.stopAccelerometerUpdates()
                Task { await continuationActor.finish() }
            },

            stream: {
                AsyncStream(RawDataSample.self) { continuation in
                    Task { await continuationActor.setContinuation(continuation) }

                    continuation.onTermination = { _ in
                        Task { await continuationActor.finish() }
                        motionManager.stopAccelerometerUpdates()
                    }
                }
            }
        )
    }()
}

extension RawDataClient {
    actor ContinuationActor {
        private var continuation: AsyncStream<RawDataSample>.Continuation?

        func setContinuation(_ newContinuation: AsyncStream<RawDataSample>.Continuation) {
            continuation = newContinuation
        }

        func yield(_ value: RawDataSample) {
            continuation?.yield(value)
        }

        func finish() {
            continuation?.finish()
        }
    }
}

