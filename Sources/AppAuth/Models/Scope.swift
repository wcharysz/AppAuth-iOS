import Foundation

/// Standard OpenID Connect / OAuth 2.0 scopes.
public struct Scope: RawRepresentable, Sendable, Equatable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// OpenID Connect scope.
    public static let openID = Scope(rawValue: "openid")

    /// Profile scope.
    public static let profile = Scope(rawValue: "profile")

    /// Email scope.
    public static let email = Scope(rawValue: "email")

    /// Address scope.
    public static let address = Scope(rawValue: "address")

    /// Phone scope.
    public static let phone = Scope(rawValue: "phone")

    /// Offline access (refresh token) scope.
    public static let offlineAccess = Scope(rawValue: "offline_access")

    /// Builds a space-separated scope string from an array of scopes.
    public static func scopeString(from scopes: [Scope]) -> String {
        scopes.map(\.rawValue).joined(separator: " ")
    }
}
