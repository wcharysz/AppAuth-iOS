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

    /// How long before the real expiry the access token is treated as stale, so a
    /// proactive refresh can happen before a token expires in the middle of a request.
    public static let refreshBuffer: TimeInterval = 60

    /// The date at which the access token should be proactively refreshed.
    ///
    /// This is the expiration date minus the refresh buffer (capped at half the token's
    /// lifetime to avoid refresh loops for short-lived tokens). `nil` when there is no
    /// token or the token never expires.
    public var nextRefreshDate: Date? {
        guard accessToken != nil, let expirationDate = accessTokenExpirationDate else {
            return nil
        }
        return expirationDate.addingTimeInterval(-effectiveRefreshBuffer)
    }

    /// Whether the access token is expired or within the refresh buffer window.
    public var needsRefresh: Bool {
        guard let nextRefreshDate else { return false }
        return Date() >= nextRefreshDate
    }

    /// The refresh buffer to apply, never larger than half the token's lifetime.
    private var effectiveRefreshBuffer: TimeInterval {
        guard let expirationDate = accessTokenExpirationDate,
              let responseDate = lastTokenResponse?.tokenResponseDate else {
            return Self.refreshBuffer
        }
        let lifetime = expirationDate.timeIntervalSince(responseDate)
        return min(Self.refreshBuffer, max(0, lifetime / 2))
    }

    // Keeps the refresh token if a new token response doesn't include one
    private var _previousRefreshToken: String?

    /// In-flight refresh task, used to coalesce concurrent refresh attempts.
    private var _refreshTask: Task<TokenResponse, Error>?

    private let authorizationService: AuthorizationService

    public init(httpClient: HTTPClient = LoggingHTTPClient()) {
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
        if !needsRefresh, let accessToken {
            try await action(accessToken, idToken)
            return
        }

        let tokenResponse = try await coalescedRefresh()

        guard let newAccessToken = tokenResponse.accessToken else {
            throw AuthError.invalidTokenResponse
        }

        try await action(newAccessToken, tokenResponse.idToken)
    }

    /// Ensures a valid session exists, refreshing the access token if it is expired or
    /// within the refresh buffer window. If there is no session, or the refresh fails,
    /// the state is cleared so the app returns to a signed-out state.
    /// - Returns: `true` if a valid session exists afterwards; otherwise `false`.
    @discardableResult
    public func ensureValidSession() async -> Bool {
        guard isAuthorized else { return false }
        guard needsRefresh else { return true }

        do {
            _ = try await coalescedRefresh()
            return true
        } catch {
            clear()
            return false
        }
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
