import Testing
import Foundation
@testable import AppAuth

@Suite("TokenRequest Tests")
struct TokenRequestTests {
    @Test("Code exchange request has correct body")
    func codeExchangeBody() {
        let authRequest = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let authResponse = AuthorizationResponse(
            request: authRequest,
            authorizationCode: "test-code",
            state: authRequest.state,
            accessToken: nil,
            tokenType: nil,
            additionalParameters: [:]
        )

        let tokenRequest = TokenRequest.exchangeCode(from: authResponse)
        let bodyString = String(data: tokenRequest.httpBody, encoding: .utf8) ?? ""

        #expect(bodyString.contains("grant_type=authorization_code"))
        #expect(bodyString.contains("code=test-code"))
        #expect(bodyString.contains("client_id=\(TestFixtures.clientID)"))
        #expect(bodyString.contains("redirect_uri="))
    }

    @Test("Refresh token request has correct body")
    func refreshTokenBody() {
        let tokenRequest = TokenRequest.refresh(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            refreshToken: "test-refresh-token"
        )

        let bodyString = String(data: tokenRequest.httpBody, encoding: .utf8) ?? ""

        #expect(bodyString.contains("grant_type=refresh_token"))
        #expect(bodyString.contains("refresh_token=test-refresh-token"))
        #expect(bodyString.contains("client_id=\(TestFixtures.clientID)"))
    }

    @Test("Client credentials request has correct body")
    func clientCredentialsBody() {
        let tokenRequest = TokenRequest.clientCredentials(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            clientSecret: TestFixtures.clientSecret,
            scopes: [.openID, .profile]
        )

        let bodyString = String(data: tokenRequest.httpBody, encoding: .utf8) ?? ""

        #expect(bodyString.contains("grant_type=client_credentials"))
        #expect(bodyString.contains("client_id=\(TestFixtures.clientID)"))
        #expect(bodyString.contains("client_secret=\(TestFixtures.clientSecret)"))
        #expect(bodyString.contains("scope=openid%20profile"))
    }

    @Test("PKCE code verifier included in code exchange")
    func codeVerifierIncluded() {
        let authRequest = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL,
            usePKCE: true
        )

        let authResponse = AuthorizationResponse(
            request: authRequest,
            authorizationCode: "code",
            state: authRequest.state,
            accessToken: nil,
            tokenType: nil,
            additionalParameters: [:]
        )

        let tokenRequest = TokenRequest.exchangeCode(from: authResponse)
        let bodyString = String(data: tokenRequest.httpBody, encoding: .utf8) ?? ""

        #expect(bodyString.contains("code_verifier="))
        #expect(tokenRequest.codeVerifier == authRequest.codeVerifier)
    }

    @Test("Additional parameters included in body")
    func additionalParameters() {
        let tokenRequest = TokenRequest(
            configuration: TestFixtures.configuration,
            grantType: .authorizationCode,
            clientID: TestFixtures.clientID,
            additionalParameters: ["audience": "https://api.example.com"]
        )

        let bodyString = String(data: tokenRequest.httpBody, encoding: .utf8) ?? ""
        #expect(bodyString.contains("audience=https%3A%2F%2Fapi.example.com"))
    }
}
