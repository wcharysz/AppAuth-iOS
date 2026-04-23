import Testing
import Foundation
@testable import AppAuth

@Suite("AuthorizationResponse Tests")
struct AuthorizationResponseTests {
    @Test("Parse authorization code from redirect URL")
    func parseAuthCode() throws {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let redirectURL = URL(string: "com.example.app://callback?code=test-auth-code&state=\(request.state)")!
        let response = try AuthorizationResponse.from(redirectURL: redirectURL, request: request)

        #expect(response.authorizationCode == "test-auth-code")
        #expect(response.state == request.state)
    }

    @Test("State mismatch throws error")
    func stateMismatch() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let redirectURL = URL(string: "com.example.app://callback?code=test-code&state=wrong-state")!
        #expect(throws: AuthError.stateMismatch) {
            try AuthorizationResponse.from(redirectURL: redirectURL, request: request)
        }
    }

    @Test("OAuth error in redirect URL throws")
    func oauthError() {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let redirectURL = URL(string: "com.example.app://callback?error=access_denied&error_description=User%20denied&state=\(request.state)")!

        #expect {
            try AuthorizationResponse.from(redirectURL: redirectURL, request: request)
        } throws: { error in
            guard let authError = error as? AuthError,
                  case let .oauthError(code, description) = authError
            else { return false }
            return code == "access_denied" && description == "User denied"
        }
    }

    @Test("Additional parameters are captured")
    func additionalParameters() throws {
        let request = AuthorizationRequest(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            redirectURL: TestFixtures.redirectURL
        )

        let redirectURL = URL(string: "com.example.app://callback?code=abc&state=\(request.state)&session_state=xyz123")!
        let response = try AuthorizationResponse.from(redirectURL: redirectURL, request: request)

        #expect(response.additionalParameters["session_state"] == "xyz123")
    }
}
