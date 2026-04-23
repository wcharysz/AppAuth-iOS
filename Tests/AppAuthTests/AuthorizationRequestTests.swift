import Testing
import Foundation
@testable import AppAuth

@Suite("AuthorizationRequest Tests")
struct AuthorizationRequestTests {
    @Test("Default PKCE enabled")
    func defaultPKCE() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        #expect(request.codeVerifier != nil)
        #expect(request.codeChallenge != nil)
        #expect(request.codeChallengeMethod == "S256")
        #expect(request.responseType == .code)
        #expect(!request.state.isEmpty)
    }

    @Test("PKCE disabled")
    func noPKCE() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL,
            usePKCE: false
        )

        #expect(request.codeVerifier == nil)
        #expect(request.codeChallenge == nil)
        #expect(request.codeChallengeMethod == nil)
    }

    @Test("Authorization URL contains required parameters")
    func authorizationURLParameters() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            scopes: [.openID, .profile],
            redirectURL: TestFixtures.redirectURL,
            additionalParameters: ["login_hint": "user@example.com"]
        )

        let url = request.authorizationURL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let queryDict = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })

        #expect(queryDict["response_type"] == "code")
        #expect(queryDict["client_id"] == TestFixtures.clientID)
        #expect(queryDict["redirect_uri"] == TestFixtures.redirectURL.absoluteString)
        #expect(queryDict["state"] == request.state)
        #expect(queryDict["scope"] == "openid profile")
        #expect(queryDict["code_challenge"] == request.codeChallenge)
        #expect(queryDict["code_challenge_method"] == "S256")
        #expect(queryDict["login_hint"] == "user@example.com")
    }

    @Test("Authorization URL base matches endpoint")
    func authorizationURLBase() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let url = request.authorizationURL
        #expect(url.scheme == "https")
        #expect(url.host == "accounts.example.com")
        #expect(url.path == "/authorize")
    }

    @Test("Nonce included when specified")
    func nonceIncluded() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL,
            nonce: "test-nonce-123"
        )

        let url = request.authorizationURL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let nonceItem = components.queryItems?.first(where: { $0.name == "nonce" })
        #expect(nonceItem?.value == "test-nonce-123")
    }

    @Test("State is unique per request")
    func uniqueState() {
        let request1 = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )
        let request2 = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        #expect(request1.state != request2.state)
    }
}
