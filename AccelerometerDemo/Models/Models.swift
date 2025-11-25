//
//  Models.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import Foundation

public struct RawDataSample: Codable, Sendable {
    let timestamp: TimeInterval
    let x: Float
    let y: Float
    let z: Float
}

public struct RawDataBatch: Codable, Sendable {
    let collectedAt: TimeInterval
    let samples: [RawDataSample]
}
