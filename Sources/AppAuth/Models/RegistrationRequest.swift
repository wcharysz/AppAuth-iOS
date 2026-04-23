import Foundation

/// An OpenID Connect Dynamic Client Registration request (RFC 7591).
public struct RegistrationRequest: Sendable {
    /// The service configuration for the provider.
    public let configuration: ServiceConfiguration

    /// The redirect URIs for the client.
    public let redirectURIs: [URL]

    /// The response types the client will use.
    public let responseTypes: [ResponseType]

    /// The grant types the client will use.
    public let grantTypes: [GrantType]

    /// The subject type requested.
    public let subjectType: String?

    /// The token endpoint authentication method.
    public let tokenEndpointAuthMethod: String?

    /// Additional parameters to include in the registration request.
    public let additionalParameters: [String: String]

    public init(
        configuration: ServiceConfiguration,
        redirectURIs: [URL],
        responseTypes: [ResponseType] = [.code],
        grantTypes: [GrantType] = [.authorizationCode],
        subjectType: String? = nil,
        tokenEndpointAuthMethod: String? = nil,
        additionalParameters: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.redirectURIs = redirectURIs
        self.responseTypes = responseTypes
        self.grantTypes = grantTypes
        self.subjectType = subjectType
        self.tokenEndpointAuthMethod = tokenEndpointAuthMethod
        self.additionalParameters = additionalParameters
    }

    /// Builds the JSON body for the registration request.
    public func jsonBody() throws -> Data {
        var body: [String: Any] = [
            "redirect_uris": redirectURIs.map(\.absoluteString),
            "response_types": responseTypes.map(\.rawValue),
            "grant_types": grantTypes.map(\.rawValue),
        ]

        if let subjectType { body["subject_type"] = subjectType }
        if let tokenEndpointAuthMethod { body["token_endpoint_auth_method"] = tokenEndpointAuthMethod }

        for (key, value) in additionalParameters {
            body[key] = value
        }

        return try JSONSerialization.data(withJSONObject: body)
    }
}
