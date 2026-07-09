import Foundation

/// High-level authorization service coordinating the full OAuth 2.0 / OpenID Connect flow.
public actor AuthorizationService {
    private let tokenService: TokenService

    public init(httpClient: HTTPClient = LoggingHTTPClient()) {
        self.tokenService = TokenService(httpClient: httpClient)
    }

    /// Performs the full authorization code exchange after receiving a redirect URL.
    public func handleRedirect(
        url: URL,
        for request: AuthorizationRequest,
        additionalTokenParameters: [String: String] = [:]
    ) async throws -> (AuthorizationResponse, TokenResponse) {
        let authResponse = try AuthorizationResponse.from(redirectURL: url, request: request)

        guard authResponse.authorizationCode != nil else {
            throw AuthError.unexpected("No authorization code in response")
        }

        let tokenResponse = try await tokenService.exchangeCode(
            from: authResponse,
            additionalParameters: additionalTokenParameters
        )

        return (authResponse, tokenResponse)
    }

    /// Refreshes tokens using the token service.
    public func refreshAccessToken(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String? = nil,
        refreshToken: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) async throws -> TokenResponse {
        try await tokenService.refreshToken(
            configuration: configuration,
            clientID: clientID,
            clientSecret: clientSecret,
            refreshToken: refreshToken,
            scopes: scopes,
            additionalParameters: additionalParameters
        )
    }

    /// Performs a client credentials token request.
    public func clientCredentials(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) async throws -> TokenResponse {
        try await tokenService.clientCredentials(
            configuration: configuration,
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes,
            additionalParameters: additionalParameters
        )
    }

    /// Performs a custom token request.
    public func performTokenRequest(_ request: TokenRequest) async throws -> TokenResponse {
        try await tokenService.performTokenRequest(request)
    }
}
