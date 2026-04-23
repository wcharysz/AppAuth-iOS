import Foundation

/// An abstraction over URL session for making HTTP requests.
/// Allows injecting mock implementations for testing.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    // URLSession already conforms — its `data(for:)` method matches the protocol.
}
