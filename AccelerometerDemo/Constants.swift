//
//  Constants.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

struct Constants {
    static let maxLinesInUI = 20
    static let accelerometerFrequencyInHz = 1.0 / 50.0 // taken from Apple docu
    static let batchSizeInSeconds = 5
    static let rawDataThreshold: Float = 0 // use 0.1 for better showcase of changes (idk, for me this was good when I was playing with it)
    
    static let backendURL = "https://something.com/"
}
