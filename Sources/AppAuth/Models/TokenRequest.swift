import Foundation

/// An OAuth 2.0 token request.
public struct TokenRequest: Sendable {
    /// The service configuration for the provider.
    public let configuration: ServiceConfiguration

    /// The grant type for this token request.
    public let grantType: GrantType

    /// The client identifier.
    public let clientID: String

    /// The client secret, if applicable.
    public let clientSecret: String?

    /// The authorization code (for authorization code exchange).
    public let authorizationCode: String?

    /// The redirect URI (must match the authorization request).
    public let redirectURL: URL?

    /// The requested scopes.
    public let scopes: [Scope]

    /// The refresh token (for token refresh).
    public let refreshToken: String?

    /// The PKCE code verifier (for authorization code exchange).
    public let codeVerifier: String?

    /// Additional parameters to include in the token request.
    public let additionalParameters: [String: String]

    public init(
        configuration: ServiceConfiguration,
        grantType: GrantType,
        clientID: String,
        clientSecret: String? = nil,
        authorizationCode: String? = nil,
        redirectURL: URL? = nil,
        scopes: [Scope] = [],
        refreshToken: String? = nil,
        codeVerifier: String? = nil,
        additionalParameters: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.grantType = grantType
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.authorizationCode = authorizationCode
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.refreshToken = refreshToken
        self.codeVerifier = codeVerifier
        self.additionalParameters = additionalParameters
    }

    /// Creates a token request from an authorization response (code exchange).
    public static func exchangeCode(
        from authResponse: AuthorizationResponse,
        additionalParameters: [String: String] = [:]
    ) -> TokenRequest {
        TokenRequest(
            configuration: authResponse.request.configuration,
            grantType: .authorizationCode,
            clientID: authResponse.request.clientID,
            clientSecret: authResponse.request.clientSecret,
            authorizationCode: authResponse.authorizationCode,
            redirectURL: authResponse.request.redirectURL,
            scopes: authResponse.request.scopes,
            codeVerifier: authResponse.request.codeVerifier,
            additionalParameters: additionalParameters
        )
    }

    /// Creates a token refresh request.
    public static func refresh(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String? = nil,
        refreshToken: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) -> TokenRequest {
        TokenRequest(
            configuration: configuration,
            grantType: .refreshToken,
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes,
            refreshToken: refreshToken,
            additionalParameters: additionalParameters
        )
    }

    /// Creates a client credentials token request.
    public static func clientCredentials(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String,
        scopes: [Scope] = [],
        additionalParameters: [String: String] = [:]
    ) -> TokenRequest {
        TokenRequest(
            configuration: configuration,
            grantType: .clientCredentials,
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes,
            additionalParameters: additionalParameters
        )
    }

    /// Builds the URL-encoded form body for the token request.
    public var httpBody: Data {
        var params: [(String, String)] = [
            ("grant_type", grantType.rawValue),
            ("client_id", clientID),
        ]

        if let clientSecret { params.append(("client_secret", clientSecret)) }
        if let authorizationCode { params.append(("code", authorizationCode)) }
        if let redirectURL { params.append(("redirect_uri", redirectURL.absoluteString)) }
        if let refreshToken { params.append(("refresh_token", refreshToken)) }
        if let codeVerifier { params.append(("code_verifier", codeVerifier)) }

        let scopeString = Scope.scopeString(from: scopes)
        if !scopeString.isEmpty {
            params.append(("scope", scopeString))
        }

        for (key, value) in additionalParameters.sorted(by: { $0.key < $1.key }) {
            params.append((key, value))
        }

        let body = params
            .map { "\(URLQueryBuilder.percentEncode($0.0))=\(URLQueryBuilder.percentEncode($0.1))" }
            .joined(separator: "&")
        return Data(body.utf8)
    }
}
