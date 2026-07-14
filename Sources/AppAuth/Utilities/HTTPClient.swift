import Foundation
import HTTPTypes
import HTTPTypesFoundation

/// An abstraction over URL session for making HTTP requests.
/// Allows injecting mock implementations for testing.
public protocol HTTPClient: Sendable {
    func data(for request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse)
}

public extension HTTPClient {
    func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse) {
        try await data(for: request, body: nil)
    }
}

extension URLSession: HTTPClient {
    public func data(for request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        if let body {
            return try await upload(for: request, from: body)
        }

        return try await data(for: request)
    }
}
