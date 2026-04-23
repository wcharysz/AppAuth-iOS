import Foundation

/// The response from an OpenID Connect Dynamic Client Registration request (RFC 7591).
public struct RegistrationResponse: Sendable, Equatable {
    /// The registered client identifier.
    public let clientID: String

    /// The registered client secret, if issued.
    public let clientSecret: String?

    /// The expiration date of the client secret, if applicable.
    public let clientSecretExpiresAt: Date?

    /// The client ID issued at date.
    public let clientIDIssuedAt: Date?

    /// The registration access token for managing the registration.
    public let registrationAccessToken: String?

    /// The registration client URI for managing the registration.
    public let registrationClientURI: URL?

    /// The token endpoint authentication method.
    public let tokenEndpointAuthMethod: String?

    /// Additional parameters from the response.
    public let additionalParameters: [String: String]

    /// Parses a registration response from JSON data.
    public static func from(data: Data) throws -> RegistrationResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Check for OAuth error
        if let errorCode = json["error"] as? String {
            throw AuthError.oauthError(
                code: errorCode,
                description: json["error_description"] as? String
            )
        }

        guard let clientID = json["client_id"] as? String else {
            throw AuthError.unexpected("Missing client_id in registration response")
        }

        let knownKeys: Set<String> = [
            "client_id", "client_secret", "client_secret_expires_at",
            "client_id_issued_at", "registration_access_token",
            "registration_client_uri", "token_endpoint_auth_method",
            "error", "error_description"
        ]

        let additional = json
            .filter { !knownKeys.contains($0.key) }
            .compactMapValues { $0 as? String }

        var secretExpiresAt: Date?
        if let timestamp = json["client_secret_expires_at"] as? TimeInterval, timestamp > 0 {
            secretExpiresAt = Date(timeIntervalSince1970: timestamp)
        }

        var clientIDIssuedAt: Date?
        if let timestamp = json["client_id_issued_at"] as? TimeInterval {
            clientIDIssuedAt = Date(timeIntervalSince1970: timestamp)
        }

        var registrationClientURI: URL?
        if let uriString = json["registration_client_uri"] as? String {
            registrationClientURI = URL(string: uriString)
        }

        return RegistrationResponse(
            clientID: clientID,
            clientSecret: json["client_secret"] as? String,
            clientSecretExpiresAt: secretExpiresAt,
            clientIDIssuedAt: clientIDIssuedAt,
            registrationAccessToken: json["registration_access_token"] as? String,
            registrationClientURI: registrationClientURI,
            tokenEndpointAuthMethod: json["token_endpoint_auth_method"] as? String,
            additionalParameters: additional
        )
    }
}
