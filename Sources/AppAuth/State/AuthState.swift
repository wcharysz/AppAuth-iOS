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

    /// In-flight refresh task, used to coalesce concurrent refresh attempts.
    private var _refreshTask: Task<TokenResponse, Error>?

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
        self.configuration = nil
        self.clientID = nil
        self.clientSecret = nil
        self.lastAuthorizationResponse = nil
        self.lastTokenResponse = nil
        self._previousRefreshToken = nil
        self._refreshTask?.cancel()
        self._refreshTask = nil
        self.lastError = nil
    }

    /// Performs an action with a fresh access token, automatically refreshing if needed.
    /// Throws if no refresh token is available and the access token is expired.
    /// Concurrent calls coalesce into a single refresh request.
    public func performAction(
        freshTokens action: @Sendable (String, String?) async throws -> Void
    ) async throws {
        if !isAccessTokenExpired, let accessToken {
            try await action(accessToken, idToken)
            return
        }

        let tokenResponse = try await coalescedRefresh()

        guard let newAccessToken = tokenResponse.accessToken else {
            throw AuthError.invalidTokenResponse
        }

        try await action(newAccessToken, tokenResponse.idToken)
    }

    /// Coalesces concurrent refresh attempts into a single in-flight request.
    /// All callers awaiting a refresh share the same `Task` and receive the same result.
    private func coalescedRefresh() async throws -> TokenResponse {
        if let existing = _refreshTask {
            return try await existing.value
        }

        guard let config = configuration,
              let clientID = clientID,
              let currentRefreshToken = refreshToken
        else {
            throw AuthError.noRefreshToken
        }

        let task = Task {
            try await authorizationService.refreshAccessToken(
                configuration: config,
                clientID: clientID,
                clientSecret: clientSecret,
                refreshToken: currentRefreshToken
            )
        }
        _refreshTask = task

        do {
            let response = try await task.value
            updateToken(response)
            _refreshTask = nil
            return response
        } catch {
            _refreshTask = nil
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

        let responseDate = data.lastTokenResponseDate ?? Date()
        let expiresIn: Int? = data.accessTokenExpirationDate.map { expDate in
            max(0, Int(expDate.timeIntervalSince(responseDate)))
        }

        self.lastTokenResponse = TokenResponse(
            accessToken: data.accessToken,
            tokenType: data.tokenType,
            expiresIn: expiresIn,
            refreshToken: data.refreshToken,
            scope: data.scope,
            idToken: data.idToken,
            tokenResponseDate: responseDate
        )
    }
}
