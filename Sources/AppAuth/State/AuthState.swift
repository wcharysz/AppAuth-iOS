import Foundation
import Observation

/// Observable auth state that manages the current authorization and token state.
/// Use this as the central source of truth for authentication in your SwiftUI app.
@Observable
@MainActor
public final class AuthState {
    /// The service configuration for the provider.
    public private(set) var configuration: ServiceConfiguration?

    /// The client identifier.
    public private(set) var clientID: String?

    /// The client secret, if applicable.
    public private(set) var clientSecret: String?

    /// The last received authorization response.
    public private(set) var lastAuthorizationResponse: AuthorizationResponse?

    /// The last received token response.
    public private(set) var lastTokenResponse: TokenResponse?

    /// The last error that occurred.
    public private(set) var lastError: AuthError?

    /// Whether the user is currently authorized (has valid tokens).
    public var isAuthorized: Bool {
        lastTokenResponse?.accessToken != nil
    }

    /// The current access token.
    public var accessToken: String? {
        lastTokenResponse?.accessToken
    }

    /// The current refresh token (may carry over from previous responses).
    public var refreshToken: String? {
        lastTokenResponse?.refreshToken ?? _previousRefreshToken
    }

    /// The current ID token.
    public var idToken: String? {
        lastTokenResponse?.idToken
    }

    /// Whether the access token has expired.
    public var isAccessTokenExpired: Bool {
        lastTokenResponse?.isAccessTokenExpired ?? true
    }

    /// The access token expiration date.
    public var accessTokenExpirationDate: Date? {
        lastTokenResponse?.accessTokenExpirationDate
    }

    // Keeps the refresh token if a new token response doesn't include one
    private var _previousRefreshToken: String?

    private let authorizationService: AuthorizationService

    public init(httpClient: HTTPClient = URLSession.shared) {
        self.authorizationService = AuthorizationService(httpClient: httpClient)
    }

    /// Updates the state with an authorization response and token response.
    public func update(
        authorizationResponse: AuthorizationResponse,
        tokenResponse: TokenResponse
    ) {
        self.configuration = authorizationResponse.request.configuration
        self.clientID = authorizationResponse.request.clientID
        self.clientSecret = authorizationResponse.request.clientSecret
        self.lastAuthorizationResponse = authorizationResponse
        updateToken(tokenResponse)
        self.lastError = nil
    }

    /// Updates the state with a new token response (e.g., from a refresh).
    public func updateToken(_ tokenResponse: TokenResponse) {
        if let existingRefreshToken = lastTokenResponse?.refreshToken {
            _previousRefreshToken = existingRefreshToken
        }
        self.lastTokenResponse = tokenResponse
        self.lastError = nil
    }

    /// Sets the error state.
    public func setError(_ error: AuthError) {
        self.lastError = error
    }

    /// Clears all auth state (logout).
    public func clear() {
        self.lastAuthorizationResponse = nil
        self.lastTokenResponse = nil
        self._previousRefreshToken = nil
        self.lastError = nil
    }

    /// Performs an action with a fresh access token, automatically refreshing if needed.
    /// Throws if no refresh token is available and the access token is expired.
    public func performAction(
        freshTokens action: @Sendable (String, String?) async throws -> Void
    ) async throws {
        if !isAccessTokenExpired, let accessToken {
            try await action(accessToken, idToken)
            return
        }

        // Need to refresh
        guard let config = configuration,
              let clientID = clientID,
              let currentRefreshToken = refreshToken
        else {
            throw AuthError.noRefreshToken
        }

        do {
            let newTokenResponse = try await authorizationService.refreshAccessToken(
                configuration: config,
                clientID: clientID,
                clientSecret: clientSecret,
                refreshToken: currentRefreshToken
            )
            updateToken(newTokenResponse)

            guard let newAccessToken = newTokenResponse.accessToken else {
                throw AuthError.invalidTokenResponse
            }

            try await action(newAccessToken, newTokenResponse.idToken)
        } catch {
            if let authError = error as? AuthError {
                setError(authError)
            }
            throw error
        }
    }

    /// Serializes the current state for storage.
    public func exportStateData() -> AuthStateData? {
        guard let configuration, let clientID else { return nil }
        return AuthStateData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            tokenType: lastTokenResponse?.tokenType,
            scope: lastTokenResponse?.scope,
            accessTokenExpirationDate: accessTokenExpirationDate,
            lastTokenResponseDate: lastTokenResponse?.tokenResponseDate,
            issuer: configuration.issuer,
            clientID: clientID,
            clientSecret: clientSecret
        )
    }

    /// Restores state from saved data (requires the full service configuration).
    public func restore(from data: AuthStateData, configuration: ServiceConfiguration) {
        self.configuration = configuration
        self.clientID = data.clientID
        self.clientSecret = data.clientSecret
        self.lastTokenResponse = TokenResponse(
            accessToken: data.accessToken,
            tokenType: data.tokenType,
            expiresIn: nil,
            refreshToken: data.refreshToken,
            scope: data.scope,
            idToken: data.idToken,
            tokenResponseDate: data.lastTokenResponseDate ?? Date()
        )
    }
}
