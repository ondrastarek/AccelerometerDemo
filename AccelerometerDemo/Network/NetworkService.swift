//
//  NetworkService.swift
//  AccelerometerDemo
//
//  Created by Ondřej Stárek on 11/25/25.
//

import Foundation

public protocol NetworkServicing {
    func send(_ batch: RawDataBatch) async throws
}

public enum NetworkError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case badStatusCode(Int, Data)
}

public final class NetworkService: NetworkServicing {

    public init() {}

    public func send(_ batch: RawDataBatch) async throws {
        do {
            let body = try JSONEncoder().encode(batch)

            guard let url = URL(string: Constants.backendURL) else {
                throw NetworkError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(http.statusCode) else {
                throw NetworkError.badStatusCode(http.statusCode, data)
            }

            print("request: \(batch.samples.count) samples, \(body.count) bytes")
            print("response: \(http.statusCode)")

        } catch {
            print("Upload failed:", error)
            throw error
        }
    }
}
