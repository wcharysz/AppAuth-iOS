import Testing
import Foundation
@testable import AppAuth

@Suite("TokenResponse Tests")
struct TokenResponseTests {
    @Test("Parse token response from JSON")
    func parseFromJSON() throws {
        let json = TestFixtures.tokenResponseJSON
        let response = try TokenResponse.from(data: Data(json.utf8))

        #expect(response.accessToken == "test-access-token")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == 3600)
        #expect(response.refreshToken == "test-refresh-token")
        #expect(response.scope == "openid profile")
        #expect(response.idToken != nil)
    }

    @Test("Access token expiration date calculated")
    func expirationDate() throws {
        let json = TestFixtures.tokenResponseJSON
        let response = try TokenResponse.from(data: Data(json.utf8))

        #expect(response.accessTokenExpirationDate != nil)
        // Expiration should be ~3600 seconds from now
        let expectedExpiration = Date().addingTimeInterval(3600)
        let diff = abs(response.accessTokenExpirationDate!.timeIntervalSince(expectedExpiration))
        #expect(diff < 5) // Within 5 seconds tolerance
    }

    @Test("Token not expired when within lifetime")
    func notExpired() {
        let response = TokenResponse(
            accessToken: "token",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: nil,
            scope: nil,
            idToken: nil
        )

        #expect(!response.isAccessTokenExpired)
    }

    @Test("Token expired when past lifetime")
    func expired() {
        let response = TokenResponse(
            accessToken: "token",
            tokenType: "Bearer",
            expiresIn: -1,
            refreshToken: nil,
            scope: nil,
            idToken: nil,
            tokenResponseDate: Date().addingTimeInterval(-10)
        )

        #expect(response.isAccessTokenExpired)
    }

    @Test("OAuth error in token response throws")
    func oauthError() {
        let json = """
        {
            "error": "invalid_grant",
            "error_description": "The authorization code has expired"
        }
        """

        #expect {
            try TokenResponse.from(data: Data(json.utf8))
        } throws: { error in
            guard let authError = error as? AuthError,
                  case let .oauthError(code, _) = authError
            else { return false }
            return code == "invalid_grant"
        }
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = TokenResponse(
            accessToken: "access",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: "refresh",
            scope: "openid",
            idToken: "id-token"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)

        #expect(original == decoded)
    }
}
