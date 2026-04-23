import Foundation

/// Protocol for custom token storage implementations.
/// Implement this to persist tokens in Keychain, UserDefaults, or any other storage.
public protocol TokenStorage: Sendable {
    /// Saves the auth state data.
    func save(_ data: AuthStateData) async throws

    /// Loads the previously saved auth state data.
    func load() async throws -> AuthStateData?

    /// Clears the saved auth state data.
    func clear() async throws
}

/// Serializable representation of auth state for storage.
public struct AuthStateData: Sendable, Codable {
    public let accessToken: String?
    public let refreshToken: String?
    public let idToken: String?
    public let tokenType: String?
    public let scope: String?
    public let accessTokenExpirationDate: Date?
    public let lastTokenResponseDate: Date?
    public let issuer: URL
    public let clientID: String
    public let clientSecret: String?

    public init(
        accessToken: String?,
        refreshToken: String?,
        idToken: String?,
        tokenType: String?,
        scope: String?,
        accessTokenExpirationDate: Date?,
        lastTokenResponseDate: Date?,
        issuer: URL,
        clientID: String,
        clientSecret: String?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.tokenType = tokenType
        self.scope = scope
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.lastTokenResponseDate = lastTokenResponseDate
        self.issuer = issuer
        self.clientID = clientID
        self.clientSecret = clientSecret
    }
}
