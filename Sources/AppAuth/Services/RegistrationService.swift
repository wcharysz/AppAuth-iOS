import Foundation
import HTTPTypes

/// Service for performing OpenID Connect Dynamic Client Registration (RFC 7591).
public actor RegistrationService {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = LoggingHTTPClient()) {
        self.httpClient = httpClient
    }

    /// Registers a new client with the authorization server.
    public func register(_ registrationRequest: RegistrationRequest) async throws -> RegistrationResponse {
        guard let endpoint = registrationRequest.configuration.registrationEndpoint else {
            throw AuthError.missingEndpoint("registration_endpoint")
        }

        var request = HTTPRequest(method: .post, url: endpoint)
        request.headerFields[.contentType] = "application/json"
        let body = try registrationRequest.jsonBody()

        let (data, response) = try await httpClient.data(for: request, body: body)

          guard response.status.kind == .successful else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorCode = json["error"] as? String
            {
                throw AuthError.oauthError(
                    code: errorCode,
                    description: json["error_description"] as? String
                )
            }
            throw AuthError.serverError(statusCode: response.status.code, data: data)
        }

        return try RegistrationResponse.from(data: data)
    }
}
