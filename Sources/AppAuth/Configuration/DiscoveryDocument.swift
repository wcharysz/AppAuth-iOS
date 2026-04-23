import Foundation

/// Represents an OpenID Connect Discovery Document
/// as defined in https://openid.net/specs/openid-connect-discovery-1_0.html
public struct DiscoveryDocument: Sendable, Codable, Equatable {
    public let issuer: URL
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
    public let userinfoEndpoint: URL?
    public let jwksURI: URL?
    public let registrationEndpoint: URL?
    public let scopesSupported: [String]?
    public let responseTypesSupported: [String]?
    public let responseModesSupported: [String]?
    public let grantTypesSupported: [String]?
    public let subjectTypesSupported: [String]?
    public let idTokenSigningAlgValuesSupported: [String]?
    public let tokenEndpointAuthMethodsSupported: [String]?
    public let revocationEndpoint: URL?
    public let endSessionEndpoint: URL?
    public let deviceAuthorizationEndpoint: URL?

    enum CodingKeys: String, CodingKey {
        case issuer
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case userinfoEndpoint = "userinfo_endpoint"
        case jwksURI = "jwks_uri"
        case registrationEndpoint = "registration_endpoint"
        case scopesSupported = "scopes_supported"
        case responseTypesSupported = "response_types_supported"
        case responseModesSupported = "response_modes_supported"
        case grantTypesSupported = "grant_types_supported"
        case subjectTypesSupported = "subject_types_supported"
        case idTokenSigningAlgValuesSupported = "id_token_signing_alg_values_supported"
        case tokenEndpointAuthMethodsSupported = "token_endpoint_auth_methods_supported"
        case revocationEndpoint = "revocation_endpoint"
        case endSessionEndpoint = "end_session_endpoint"
        case deviceAuthorizationEndpoint = "device_authorization_endpoint"
    }

    /// Converts to a ``ServiceConfiguration``.
    public func asServiceConfiguration() -> ServiceConfiguration {
        ServiceConfiguration(
            issuer: issuer,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            userinfoEndpoint: userinfoEndpoint,
            revocationEndpoint: revocationEndpoint,
            registrationEndpoint: registrationEndpoint,
            endSessionEndpoint: endSessionEndpoint,
            deviceAuthorizationEndpoint: deviceAuthorizationEndpoint
        )
    }
}
