import Foundation
import Testing
@testable import AppAuth

@MainActor
@Suite("AuthState Tests")
struct AuthStateTests {
    // MARK: - Helpers

    private static func makeTokenResponse(
        accessToken: String = "access-token",
        refreshToken: String = "refresh-token",
        idToken: String = "id-token",
        expiresIn: Int? = 3600
    ) -> TokenResponse {
        TokenResponse(
            accessToken: accessToken,
            tokenType: "Bearer",
            expiresIn: expiresIn,
            refreshToken: refreshToken,
            scope: "openid",
            idToken: idToken
        )
    }

    private static func makeExpiredTokenResponse(
        accessToken: String = "expired-access",
        refreshToken: String = "refresh-token"
    ) -> TokenResponse {
        TokenResponse(
            accessToken: accessToken,
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: refreshToken,
            scope: "openid",
            idToken: "id-token",
            tokenResponseDate: Date.distantPast
        )
    }

    private static func makeAuthRequest() -> AuthorizationRequest {
        AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            clientSecret: TestFixtures.clientSecret,
            scopes: [.openID],
            redirectURL: TestFixtures.redirectURL
        )
    }

    // MARK: - Initial State

    @Test("Initial state has no authorization")
    func initialState() {
        let state = AuthState()
        #expect(state.isAuthorized == false)
        #expect(state.accessToken == nil)
        #expect(state.refreshToken == nil)
        #expect(state.idToken == nil)
        #expect(state.isAccessTokenExpired == true)
        #expect(state.lastError == nil)
        #expect(state.configuration == nil)
        #expect(state.clientID == nil)
    }

    // MARK: - updateToken

    @Test("updateToken sets token response and clears error")
    func updateTokenSetsResponse() {
        let state = AuthState()
        state.setError(.noRefreshToken)

        let token = Self.makeTokenResponse()
        state.updateToken(token)

        #expect(state.isAuthorized == true)
        #expect(state.accessToken == "access-token")
        #expect(state.refreshToken == "refresh-token")
        #expect(state.idToken == "id-token")
        #expect(state.lastError == nil)
    }

    @Test("updateToken preserves previous refresh token when new one is nil")
    func updateTokenPreservesRefreshToken() {
        let state = AuthState()
        state.updateToken(Self.makeTokenResponse(refreshToken: "original-refresh"))

        // Second token response with no refresh token
        let noRefresh = TokenResponse(
            accessToken: "new-access",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: nil,
            scope: "openid",
            idToken: nil
        )
        state.updateToken(noRefresh)

        #expect(state.accessToken == "new-access")
        #expect(state.refreshToken == "original-refresh")
    }

    // MARK: - clear

    @Test("clear resets all state including configuration and credentials")
    func clearResetsAll() {
        let state = AuthState()
        state.updateToken(Self.makeTokenResponse())
        state.setError(.noRefreshToken)

        state.clear()

        #expect(state.isAuthorized == false)
        #expect(state.accessToken == nil)
        #expect(state.refreshToken == nil)
        #expect(state.idToken == nil)
        #expect(state.lastError == nil)
        #expect(state.configuration == nil)
        #expect(state.clientID == nil)
        #expect(state.clientSecret == nil)
        #expect(state.lastAuthorizationResponse == nil)
        #expect(state.lastTokenResponse == nil)
    }

    // MARK: - exportStateData / restore

    @Test("exportStateData returns nil when configuration is missing")
    func exportNilWithoutConfig() {
        let state = AuthState()
        state.updateToken(Self.makeTokenResponse())
        #expect(state.exportStateData() == nil)
    }

    @Test("restore preserves access token expiration")
    func restorePreservesExpiration() {
        let pastExpiration = Date(timeIntervalSinceNow: -600) // 10 min ago
        let responseDate = Date(timeIntervalSinceNow: -4200) // 70 min ago

        let data = AuthStateData(
            accessToken: "restored-access",
            refreshToken: "restored-refresh",
            idToken: "restored-id",
            tokenType: "Bearer",
            scope: "openid",
            accessTokenExpirationDate: pastExpiration,
            lastTokenResponseDate: responseDate,
            issuer: TestFixtures.issuer,
            clientID: TestFixtures.clientID,
            clientSecret: nil
        )

        let state = AuthState()
        state.restore(from: data, configuration: TestFixtures.configuration)

        #expect(state.isAuthorized == true)
        #expect(state.accessToken == "restored-access")
        #expect(state.isAccessTokenExpired == true)
    }

    @Test("restore with future expiration shows token as not expired")
    func restoreWithFutureExpiration() {
        let futureExpiration = Date(timeIntervalSinceNow: 1800) // 30 min from now
        let responseDate = Date(timeIntervalSinceNow: -1800) // 30 min ago

        let data = AuthStateData(
            accessToken: "valid-access",
            refreshToken: "refresh",
            idToken: nil,
            tokenType: "Bearer",
            scope: nil,
            accessTokenExpirationDate: futureExpiration,
            lastTokenResponseDate: responseDate,
            issuer: TestFixtures.issuer,
            clientID: TestFixtures.clientID,
            clientSecret: nil
        )

        let state = AuthState()
        state.restore(from: data, configuration: TestFixtures.configuration)

        #expect(state.isAccessTokenExpired == false)
    }

    @Test("export and restore round-trip preserves state")
    func exportRestoreRoundTrip() {
        let mockClient = MockHTTPClient(
            responseData: Data(TestFixtures.tokenResponseJSON.utf8)
        )
        let state = AuthState(httpClient: mockClient)

        let token = Self.makeTokenResponse()
        state.updateToken(token)

        // Manually set config/clientID so export works
        state.restore(
            from: AuthStateData(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                idToken: token.idToken,
                tokenType: token.tokenType,
                scope: token.scope,
                accessTokenExpirationDate: token.accessTokenExpirationDate,
                lastTokenResponseDate: token.tokenResponseDate,
                issuer: TestFixtures.issuer,
                clientID: TestFixtures.clientID,
                clientSecret: TestFixtures.clientSecret
            ),
            configuration: TestFixtures.configuration
        )

        let exported = state.exportStateData()
        #expect(exported != nil)
        #expect(exported?.accessToken == "access-token")
        #expect(exported?.refreshToken == "refresh-token")
        #expect(exported?.clientID == TestFixtures.clientID)

        // Restore into a fresh instance
        let state2 = AuthState(httpClient: mockClient)
        state2.restore(from: exported!, configuration: TestFixtures.configuration)

        #expect(state2.accessToken == state.accessToken)
        #expect(state2.refreshToken == state.refreshToken)
        #expect(state2.clientID == state.clientID)
    }

    // MARK: - performAction

    @Test("performAction uses existing token when not expired")
    func performActionUsesExistingToken() async throws {
        let state = AuthState()
        state.updateToken(Self.makeTokenResponse(accessToken: "valid-token"))

        nonisolated(unsafe) var receivedToken: String?
        try await state.performAction { token, _ in
            receivedToken = token
        }

        #expect(receivedToken == "valid-token")
    }

    @Test("performAction refreshes expired token")
    func performActionRefreshes() async throws {
        let refreshJSON = """
        {
            "access_token": "new-access",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "new-refresh",
            "id_token": "new-id"
        }
        """
        let mockClient = MockHTTPClient(responseData: Data(refreshJSON.utf8))
        let state = AuthState(httpClient: mockClient)

        // Set up state with expired token
        state.restore(
            from: AuthStateData(
                accessToken: "old-access",
                refreshToken: "old-refresh",
                idToken: nil,
                tokenType: "Bearer",
                scope: nil,
                accessTokenExpirationDate: Date.distantPast,
                lastTokenResponseDate: Date.distantPast,
                issuer: TestFixtures.issuer,
                clientID: TestFixtures.clientID,
                clientSecret: TestFixtures.clientSecret
            ),
            configuration: TestFixtures.configuration
        )

        #expect(state.isAccessTokenExpired == true)

        nonisolated(unsafe) var receivedToken: String?
        try await state.performAction { token, _ in
            receivedToken = token
        }

        #expect(receivedToken == "new-access")
        #expect(state.accessToken == "new-access")
    }

    @Test("performAction throws noRefreshToken when no refresh token available")
    func performActionThrowsWithoutRefresh() async {
        let state = AuthState()
        // Expired token with no refresh token
        state.updateToken(
            TokenResponse(
                accessToken: "expired",
                tokenType: "Bearer",
                expiresIn: 3600,
                refreshToken: nil,
                scope: nil,
                idToken: nil,
                tokenResponseDate: Date.distantPast
            )
        )

        await #expect(throws: AuthError.noRefreshToken) {
            try await state.performAction { _, _ in }
        }
    }

    @Test("performAction sets lastError on auth failure")
    func performActionSetsError() async {
        let errorJSON = """
        {"error": "invalid_grant", "error_description": "Token revoked"}
        """
        let mockClient = MockHTTPClient(responseData: Data(errorJSON.utf8))
        let state = AuthState(httpClient: mockClient)

        state.restore(
            from: AuthStateData(
                accessToken: "old",
                refreshToken: "old-refresh",
                idToken: nil,
                tokenType: "Bearer",
                scope: nil,
                accessTokenExpirationDate: Date.distantPast,
                lastTokenResponseDate: Date.distantPast,
                issuer: TestFixtures.issuer,
                clientID: TestFixtures.clientID,
                clientSecret: nil
            ),
            configuration: TestFixtures.configuration
        )

        do {
            try await state.performAction { _, _ in }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(state.lastError == .oauthError(code: "invalid_grant", description: "Token revoked"))
        }
    }

    // MARK: - Concurrent Refresh Coalescing

    @Test("concurrent performAction calls share a single refresh")
    func concurrentRefreshCoalescing() async throws {
        let refreshJSON = """
        {
            "access_token": "refreshed-access",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "refreshed-refresh"
        }
        """
        let recordingClient = RecordingHTTPClient(
            responseData: Data(refreshJSON.utf8)
        )
        let state = AuthState(httpClient: recordingClient)

        state.restore(
            from: AuthStateData(
                accessToken: "expired",
                refreshToken: "refresh",
                idToken: nil,
                tokenType: "Bearer",
                scope: nil,
                accessTokenExpirationDate: Date.distantPast,
                lastTokenResponseDate: Date.distantPast,
                issuer: TestFixtures.issuer,
                clientID: TestFixtures.clientID,
                clientSecret: nil
            ),
            configuration: TestFixtures.configuration
        )

        // Launch multiple concurrent actions that all need a refresh
        var tokens: [String] = []
        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    nonisolated(unsafe) var captured = ""
                    try await state.performAction { token, _ in
                        captured = token
                    }
                    return captured
                }
            }
            for try await token in group {
                tokens.append(token)
            }
        }

        // All callers should have received the same refreshed token
        #expect(tokens.allSatisfy { $0 == "refreshed-access" })

        // Only one HTTP request should have been made (coalesced)
        #expect(recordingClient.recordedRequests.count == 1)
    }

    // MARK: - setError

    @Test("setError sets and exposes the error")
    func setErrorWorks() {
        let state = AuthState()
        state.setError(.noRefreshToken)
        #expect(state.lastError == .noRefreshToken)
    }

    // MARK: - isAccessTokenExpired

    @Test("isAccessTokenExpired returns true when no token exists")
    func expiredWithoutToken() {
        let state = AuthState()
        #expect(state.isAccessTokenExpired == true)
    }

    @Test("isAccessTokenExpired returns false for valid token")
    func notExpiredWithValidToken() {
        let state = AuthState()
        state.updateToken(Self.makeTokenResponse(expiresIn: 3600))
        #expect(state.isAccessTokenExpired == false)
    }

    @Test("isAccessTokenExpired returns true for past token")
    func expiredWithPastToken() {
        let state = AuthState()
        state.updateToken(Self.makeExpiredTokenResponse())
        #expect(state.isAccessTokenExpired == true)
    }
}
