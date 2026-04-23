import Foundation

/// Standard OpenID Connect response types.
public struct ResponseType: RawRepresentable, Sendable, Equatable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Authorization code response type.
    public static let code = ResponseType(rawValue: "code")

    /// Implicit token response type.
    public static let token = ResponseType(rawValue: "token")

    /// OpenID Connect ID token response type.
    public static let idToken = ResponseType(rawValue: "id_token")
}
