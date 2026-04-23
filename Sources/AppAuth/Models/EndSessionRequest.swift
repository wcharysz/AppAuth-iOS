import Foundation

/// An OpenID Connect end session (RP-initiated logout) request.
public struct EndSessionRequest: Sendable {
    /// The service configuration for the provider.
    public let configuration: ServiceConfiguration

    /// The ID token hint to identify the user session.
    public let idTokenHint: String?

    /// The URI to redirect to after logout.
    public let postLogoutRedirectURL: URL?

    /// An opaque value used to maintain state between the request and callback.
    public let state: String

    /// Additional parameters to include in the end session request.
    public let additionalParameters: [String: String]

    public init(
        configuration: ServiceConfiguration,
        idTokenHint: String? = nil,
        postLogoutRedirectURL: URL? = nil,
        additionalParameters: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.idTokenHint = idTokenHint
        self.postLogoutRedirectURL = postLogoutRedirectURL
        self.state = PKCE.generateState()
        self.additionalParameters = additionalParameters
    }

    /// The fully constructed end session URL to load in the web view.
    public var endSessionURL: URL {
        get throws {
            guard let endpoint = configuration.endSessionEndpoint else {
                throw AuthError.missingEndpoint("end_session_endpoint")
            }

            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "state", value: state),
            ]

            if let idTokenHint {
                queryItems.append(URLQueryItem(name: "id_token_hint", value: idTokenHint))
            }
            if let postLogoutRedirectURL {
                queryItems.append(
                    URLQueryItem(name: "post_logout_redirect_uri", value: postLogoutRedirectURL.absoluteString)
                )
            }

            for (key, value) in additionalParameters.sorted(by: { $0.key < $1.key }) {
                queryItems.append(URLQueryItem(name: key, value: value))
            }

            components.queryItems = queryItems
            return components.url!
        }
    }
}
