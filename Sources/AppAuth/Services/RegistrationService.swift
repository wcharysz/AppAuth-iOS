import Foundation

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

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try registrationRequest.jsonBody()

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorCode = json["error"] as? String
            {
                throw AuthError.oauthError(
                    code: errorCode,
                    description: json["error_description"] as? String
                )
            }
            throw AuthError.serverError(statusCode: httpResponse.statusCode, data: data)
        }

        return try RegistrationResponse.from(data: data)
    }
}
