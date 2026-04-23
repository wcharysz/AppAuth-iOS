import Foundation
import os
@testable import AppAuth

/// A mock HTTP client for testing network operations without actual network calls.
struct MockHTTPClient: HTTPClient, Sendable {
    let responseData: Data
    let statusCode: Int
    let headers: [String: String]

    init(
        responseData: Data,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.responseData = responseData
        self.statusCode = statusCode
        self.headers = headers
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let url = request.url ?? URL(string: "https://mock.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        return (responseData, response)
    }
}

/// A mock HTTP client that records requests for verification.
final class RecordingHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])
    private let responseData: Data
    private let statusCode: Int

    var recordedRequests: [URLRequest] {
        lock.withLock { $0 }
    }

    init(responseData: Data, statusCode: Int = 200) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.withLock { $0.append(request) }

        let url = request.url ?? URL(string: "https://mock.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (responseData, response)
    }
}
