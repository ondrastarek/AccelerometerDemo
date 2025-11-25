//
//  Item.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import Foundation

struct AccelerometerSample: Codable, Sendable {
    let timestamp: TimeInterval
    let x: Float
    let y: Float
    let z: Float
}

struct AccelerometerBatch: Codable, Sendable {
    let collectedAt: TimeInterval
    let samples: [AccelerometerSample]
}
