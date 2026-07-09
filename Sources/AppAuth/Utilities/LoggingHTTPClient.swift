import Foundation
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

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<no url>"
        logger.debug("→ \(method, privacy: .public) \(url, privacy: .public)")
        logRequestDetails(request)

        let start = ContinuousClock.now
        do {
            let (data, response) = try await wrapped.data(for: request)
            let elapsed = start.duration(to: .now)
            if let http = response as? HTTPURLResponse {
                logger.debug(
                    "← \(http.statusCode, privacy: .public) \(method, privacy: .public) \(url, privacy: .public) (\(data.count, privacy: .public) bytes, \(elapsed, privacy: .public))"
                )
            } else {
                logger.debug(
                    "← \(method, privacy: .public) \(url, privacy: .public) (\(data.count, privacy: .public) bytes)"
                )
            }
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

    private func logRequestDetails(_ request: URLRequest) {
        #if DEBUG
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("  request headers: \(Self.describe(headers: headers), privacy: .public)")
        }
        if let body = request.httpBody, !body.isEmpty {
            logger.debug("  request body: \(Self.describe(body: body), privacy: .public)")
        }
        #endif
    }

    private func logResponseDetails(_ response: URLResponse, body: Data) {
        #if DEBUG
        if let http = response as? HTTPURLResponse {
            let headers = http.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                result["\(pair.key)"] = "\(pair.value)"
            }
            if !headers.isEmpty {
                logger.debug("  response headers: \(Self.describe(headers: headers), privacy: .public)")
            }
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
