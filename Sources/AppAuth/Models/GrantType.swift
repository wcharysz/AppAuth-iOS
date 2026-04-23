import Foundation

/// Standard OAuth 2.0 grant types.
public struct GrantType: RawRepresentable, Sendable, Equatable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Authorization code grant (RFC 6749 §4.1).
    public static let authorizationCode = GrantType(rawValue: "authorization_code")

    /// Implicit grant (RFC 6749 §4.2).
    public static let implicit = GrantType(rawValue: "implicit")

    /// Client credentials grant (RFC 6749 §4.4).
    public static let clientCredentials = GrantType(rawValue: "client_credentials")

    /// Refresh token grant (RFC 6749 §6).
    public static let refreshToken = GrantType(rawValue: "refresh_token")

    /// Device authorization grant (RFC 8628).
    public static let deviceCode = GrantType(rawValue: "urn:ietf:params:oauth:grant-type:device_code")
}
