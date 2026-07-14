import Foundation
import HTTPTypes

/// Represents an OpenID Connect / OAuth 2.0 provider's endpoint configuration.
public struct ServiceConfiguration: Sendable, Codable, Equatable {
    /// The issuer URL.
    public let issuer: URL

    /// The authorization endpoint URL.
    public let authorizationEndpoint: URL

    /// The token endpoint URL.
    public let tokenEndpoint: URL

    /// The userinfo endpoint URL, if available.
    public let userinfoEndpoint: URL?

    /// The token revocation endpoint URL, if available.
    public let revocationEndpoint: URL?

    /// The dynamic client registration endpoint URL, if available.
    public let registrationEndpoint: URL?

    /// The end session (logout) endpoint URL, if available.
    public let endSessionEndpoint: URL?

    /// The device authorization endpoint URL, if available.
    public let deviceAuthorizationEndpoint: URL?

    public init(
        issuer: URL,
        authorizationEndpoint: URL,
        tokenEndpoint: URL,
        userinfoEndpoint: URL? = nil,
        revocationEndpoint: URL? = nil,
        registrationEndpoint: URL? = nil,
        endSessionEndpoint: URL? = nil,
        deviceAuthorizationEndpoint: URL? = nil
    ) {
        self.issuer = issuer
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.userinfoEndpoint = userinfoEndpoint
        self.revocationEndpoint = revocationEndpoint
        self.registrationEndpoint = registrationEndpoint
        self.endSessionEndpoint = endSessionEndpoint
        self.deviceAuthorizationEndpoint = deviceAuthorizationEndpoint
    }

    /// Discovers the service configuration from an OpenID Connect issuer URL
    /// by fetching the `.well-known/openid-configuration` document.
    public static func discover(
        from issuer: URL,
        using httpClient: HTTPClient = LoggingHTTPClient()
    ) async throws -> ServiceConfiguration {
        let discoveryURL = issuer.appendingPathComponent(".well-known/openid-configuration")
        let request = HTTPRequest(url: discoveryURL)
        let (data, response) = try await httpClient.data(for: request)

        guard response.status.kind == .successful else {
            throw AuthError.serverError(
                statusCode: response.status.code,
                data: data
            )
        }

        let document = try JSONDecoder().decode(DiscoveryDocument.self, from: data)
        return document.asServiceConfiguration()
    }
}
