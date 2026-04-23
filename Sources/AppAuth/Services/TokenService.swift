import Foundation

/// Service for performing OAuth 2.0 token operations.
public actor TokenService {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = URLSession.shared) {
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
        var request = URLRequest(url: tokenRequest.configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = tokenRequest.httpBody

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            // Try to parse OAuth error from the response body
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

        return try TokenResponse.from(data: data)
    }
}
