import Foundation

/// An OAuth 2.0 authorization request using the authorization code flow with PKCE.
public struct AuthorizationRequest: Sendable {
    /// The service configuration for the provider.
    public let configuration: ServiceConfiguration

    /// The client identifier.
    public let clientID: String

    /// The client secret, if applicable.
    public let clientSecret: String?

    /// The requested scopes.
    public let scopes: [Scope]

    /// The redirect URI to receive the authorization response.
    public let redirectURL: URL

    /// The response type (typically `.code`).
    public let responseType: ResponseType

    /// An opaque value used to maintain state between the request and callback.
    public let state: String

    /// A string value used to associate a client session with an ID token.
    public let nonce: String?

    /// The PKCE code verifier (kept secret, used for token exchange).
    public let codeVerifier: String?

    /// The PKCE code challenge derived from the code verifier.
    public let codeChallenge: String?

    /// The method used to derive the code challenge (always "S256").
    public let codeChallengeMethod: String?

    /// Additional parameters to include in the authorization request.
    public let additionalParameters: [String: String]

    /// Creates an authorization request with PKCE enabled by default.
    public init(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String? = nil,
        scopes: [Scope] = [.openID],
        redirectURL: URL,
        responseType: ResponseType = .code,
        nonce: String? = nil,
        usePKCE: Bool = true,
        additionalParameters: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.scopes = scopes
        self.redirectURL = redirectURL
        self.responseType = responseType
        self.state = PKCE.generateState()
        self.nonce = nonce
        self.additionalParameters = additionalParameters

        if usePKCE {
            let verifier = PKCE.generateCodeVerifier()
            self.codeVerifier = verifier
            self.codeChallenge = PKCE.generateCodeChallenge(from: verifier)
            self.codeChallengeMethod = "S256"
        } else {
            self.codeVerifier = nil
            self.codeChallenge = nil
            self.codeChallengeMethod = nil
        }
    }

    /// The fully constructed authorization URL to load in the web view.
    public var authorizationURL: URL {
        var components = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "response_type", value: responseType.rawValue),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
            URLQueryItem(name: "state", value: state),
        ]

        let scopeString = Scope.scopeString(from: scopes)
        if !scopeString.isEmpty {
            queryItems.append(URLQueryItem(name: "scope", value: scopeString))
        }

        if let nonce {
            queryItems.append(URLQueryItem(name: "nonce", value: nonce))
        }
        if let codeChallenge {
            queryItems.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
        }
        if let codeChallengeMethod {
            queryItems.append(URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod))
        }

        for (key, value) in additionalParameters.sorted(by: { $0.key < $1.key }) {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components.queryItems = queryItems
        return components.url!
    }
}
