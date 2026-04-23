import Foundation

/// The response from an OAuth 2.0 token request.
public struct TokenResponse: Sendable, Codable, Equatable {
    /// The access token issued by the authorization server.
    public let accessToken: String?

    /// The type of the token (typically "Bearer").
    public let tokenType: String?

    /// The lifetime in seconds of the access token.
    public let expiresIn: Int?

    /// The refresh token for obtaining new access tokens.
    public let refreshToken: String?

    /// The scope of the access token.
    public let scope: String?

    /// The OpenID Connect ID token.
    public let idToken: String?

    /// Any additional parameters returned in the token response.
    public let additionalParameters: [String: String]

    /// The date/time when the access token expires.
    public let accessTokenExpirationDate: Date?

    /// The date/time when this token response was received.
    public let tokenResponseDate: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case idToken = "id_token"
        case additionalParameters
        case accessTokenExpirationDate
        case tokenResponseDate
    }

    public init(
        accessToken: String?,
        tokenType: String?,
        expiresIn: Int?,
        refreshToken: String?,
        scope: String?,
        idToken: String?,
        additionalParameters: [String: String] = [:],
        tokenResponseDate: Date = Date()
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.idToken = idToken
        self.additionalParameters = additionalParameters
        self.tokenResponseDate = tokenResponseDate

        if let expiresIn {
            self.accessTokenExpirationDate = tokenResponseDate.addingTimeInterval(TimeInterval(expiresIn))
        } else {
            self.accessTokenExpirationDate = nil
        }
    }

    /// Parses a token response from JSON data.
    public static func from(data: Data) throws -> TokenResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        let knownKeys: Set<String> = [
            "access_token", "token_type", "expires_in",
            "refresh_token", "scope", "id_token", "error", "error_description"
        ]

        // Check for OAuth error
        if let errorCode = json["error"] as? String {
            throw AuthError.oauthError(
                code: errorCode,
                description: json["error_description"] as? String
            )
        }

        let additional = json
            .filter { !knownKeys.contains($0.key) }
            .compactMapValues { $0 as? String }

        return TokenResponse(
            accessToken: json["access_token"] as? String,
            tokenType: json["token_type"] as? String,
            expiresIn: json["expires_in"] as? Int,
            refreshToken: json["refresh_token"] as? String,
            scope: json["scope"] as? String,
            idToken: json["id_token"] as? String,
            additionalParameters: additional
        )
    }

    /// Whether the access token has expired.
    public var isAccessTokenExpired: Bool {
        guard let expirationDate = accessTokenExpirationDate else { return false }
        return Date() > expirationDate
    }
}
