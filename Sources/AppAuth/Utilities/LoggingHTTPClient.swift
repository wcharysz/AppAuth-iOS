import Foundation
import HTTPTypes
import os

/// An `HTTPClient` decorator that logs every outgoing request and its response to the
/// unified logging system (visible in the Xcode console and Console.app).
///
/// In **release** builds it logs only the HTTP method, URL, response status code, payload
/// size and elapsed time. Request/response bodies and headers are intentionally **not**
/// logged to avoid leaking credentials, tokens or authorization codes.
///
/// In **DEBUG** builds it additionally logs the full request headers and body as well as
/// the response headers and body, so you can inspect exactly what AppAuth exchanges with
/// the provider. These verbose entries are compiled out of release builds entirely.
public struct LoggingHTTPClient: HTTPClient {
    private let wrapped: HTTPClient
    private let logger: Logger

    /// Creates a logging client that forwards requests to `wrapped`.
    /// - Parameters:
    ///   - wrapped: The underlying client that performs the request. Defaults to `URLSession.shared`.
    ///   - logger: The logger used to emit messages. Defaults to the `AppAuth` "HTTP" category.
    public init(
        wrapping wrapped: HTTPClient = URLSession.shared,
        logger: Logger = Logger(subsystem: "AppAuth", category: "HTTP")
    ) {
        self.wrapped = wrapped
        self.logger = logger
    }

    public func data(for request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        let method = request.method.rawValue
        let url = request.url?.absoluteString ?? "<no url>"
        logger.debug("→ \(method, privacy: .public) \(url, privacy: .public)")
        logRequestDetails(request, body: body)

        let start = ContinuousClock.now
        do {
            let (data, response) = try await wrapped.data(for: request, body: body)
            let elapsed = start.duration(to: .now)
            logger.debug(
                "← \(response.status.code, privacy: .public) \(method, privacy: .public) \(url, privacy: .public) (\(data.count, privacy: .public) bytes, \(elapsed, privacy: .public))"
            )
            logResponseDetails(response, body: data)
            return (data, response)
        } catch {
            logger.error(
                "✗ \(method, privacy: .public) \(url, privacy: .public) failed: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    // MARK: - Verbose logging (DEBUG only)

    private func logRequestDetails(_ request: HTTPRequest, body: Data?) {
        #if DEBUG
        if !request.headerFields.isEmpty {
            let headers = request.headerFields.reduce(into: [String: String]()) { result, field in
                result[field.name.rawName] = field.value
            }
            logger.debug("  request headers: \(Self.describe(headers: headers), privacy: .public)")
        }
        if let body, !body.isEmpty {
            logger.debug("  request body: \(Self.describe(body: body), privacy: .public)")
        }
        #endif
    }

    private func logResponseDetails(_ response: HTTPResponse, body: Data) {
        #if DEBUG
        let headers = response.headerFields.reduce(into: [String: String]()) { result, field in
            result[field.name.rawName] = field.value
        }
        if !headers.isEmpty {
            logger.debug("  response headers: \(Self.describe(headers: headers), privacy: .public)")
        }
        if !body.isEmpty {
            logger.debug("  response body: \(Self.describe(body: body), privacy: .public)")
        }
        #endif
    }

    #if DEBUG
    private static func describe(headers: [String: String]) -> String {
        headers
            .map { "\($0.key): \($0.value)" }
            .sorted()
            .joined(separator: ", ")
    }

    private static func describe(body: Data) -> String {
        if let text = String(data: body, encoding: .utf8) {
            return text
        }
        return "<\(body.count) bytes of binary data>"
    }
    #endif
}
