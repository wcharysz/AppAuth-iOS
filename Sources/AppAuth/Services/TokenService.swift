import Foundation
import HTTPTypes

/// Service for performing OAuth 2.0 token operations.
public actor TokenService {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = LoggingHTTPClient()) {
        self.httpClient = httpClient
    }

    /// Exchanges an authorization code for tokens.
    public func exchangeCode(
        from authResponse: AuthorizationResponse,
        additionalParameters: [String: String] = [:]
    ) async throws -> TokenResponse {
        let tokenRequest = TokenRequest.exchangeCode(
            from: authResponse,
            additionalParameters: additionalParameters
        )
        return try await performTokenRequest(tokenRequest)
    }

    /// Refreshes an access token using a refresh token.
    public func refreshToken(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String? = nil,
        refreshToken: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) async throws -> TokenResponse {
        let tokenRequest = TokenRequest.refresh(
            configuration: configuration,
            clientID: clientID,
            clientSecret: clientSecret,
            refreshToken: refreshToken,
            scopes: scopes,
            additionalParameters: additionalParameters
        )
        return try await performTokenRequest(tokenRequest)
    }

    /// Performs a client credentials token request.
    public func clientCredentials(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) async throws -> TokenResponse {
        let tokenRequest = TokenRequest.clientCredentials(
            configuration: configuration,
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes,
            additionalParameters: additionalParameters
        )
        return try await performTokenRequest(tokenRequest)
    }

    /// Performs a generic token request.
    public func performTokenRequest(_ tokenRequest: TokenRequest) async throws -> TokenResponse {
        var request = HTTPRequest(method: .post, url: tokenRequest.configuration.tokenEndpoint)
        request.headerFields[.contentType] = "application/x-www-form-urlencoded"

        let (data, response) = try await httpClient.data(for: request, body: tokenRequest.httpBody)

          guard response.status.kind == .successful else {
            // Try to parse OAuth error from the response body
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

        return try TokenResponse.from(data: data)
    }
}
