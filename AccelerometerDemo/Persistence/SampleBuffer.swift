//
//  SampleBuffer.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

public actor SampleBuffer {
    private var samples: [RawDataSample] = []

    public func append(_ sample: RawDataSample) {
        samples.append(sample)
    }

    public func flush() -> [RawDataSample] {
        defer { samples.removeAll() }
        return samples
    }
}
