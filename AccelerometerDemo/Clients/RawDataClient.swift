//
//  AccelerometerClient.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import CoreMotion
import Foundation

public struct AccelerometerClient: Sendable {
    public var isAccelerometerAvailable: () -> Bool
    public var start: @Sendable () -> Void
    public var stop: @Sendable () -> Void
    public var stream: @Sendable () -> AsyncStream<AccelerometerSample>
}

extension AccelerometerClient {
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

                    let sample = AccelerometerSample(
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
                AsyncStream(AccelerometerSample.self) { continuation in
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

extension AccelerometerClient {
    actor ContinuationActor {
        private var continuation: AsyncStream<AccelerometerSample>.Continuation?

        func setContinuation(_ newContinuation: AsyncStream<AccelerometerSample>.Continuation) {
            continuation = newContinuation
        }

        func yield(_ value: AccelerometerSample) {
            continuation?.yield(value)
        }

        func finish() {
            continuation?.finish()
        }
    }
}

