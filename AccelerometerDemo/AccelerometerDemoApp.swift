//
//  AccelerometerDemoApp.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import SwiftUI

@main
struct AccelerometerDemoApp: App {
    let accelerometer = AccelerometerClient.live

    var body: some Scene {
        WindowGroup {
            ContentView(accelerometer: accelerometer)
        }
    }
}
