import Foundation
import HTTPTypes
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

    func data(for request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        var response = HTTPResponse(status: .init(code: statusCode))
        for (name, value) in headers {
            if let fieldName = HTTPField.Name(name) {
                response.headerFields[fieldName] = value
            }
        }
        return (responseData, response)
    }
}

/// A mock HTTP client that records requests for verification.
final class RecordingHTTPClient: HTTPClient, @unchecked Sendable {
    struct RecordedRequest: Sendable {
        let request: HTTPRequest
        let body: Data?
    }

    private let lock = OSAllocatedUnfairLock<[RecordedRequest]>(initialState: [])
    private let responseData: Data
    private let statusCode: Int

    var recordedRequests: [RecordedRequest] {
        lock.withLock { $0 }
    }

    init(responseData: Data, statusCode: Int = 200) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    func data(for request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        lock.withLock { $0.append(RecordedRequest(request: request, body: body)) }

        var response = HTTPResponse(status: .init(code: statusCode))
        response.headerFields[.contentType] = "application/json"
        return (responseData, response)
    }
}
