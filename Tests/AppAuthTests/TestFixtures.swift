import Foundation
@testable import AppAuth

/// Shared test fixtures for reuse across test suites.
enum TestFixtures {
    static let issuer = URL(string: "https://accounts.example.com")!
    static let authEndpoint = URL(string: "https://accounts.example.com/authorize")!
    static let tokenEndpoint = URL(string: "https://accounts.example.com/token")!
    static let userinfoEndpoint = URL(string: "https://accounts.example.com/userinfo")!
    static let registrationEndpoint = URL(string: "https://accounts.example.com/register")!
    static let endSessionEndpoint = URL(string: "https://accounts.example.com/logout")!
    static let deviceEndpoint = URL(string: "https://accounts.example.com/device")!
    static let redirectURL = URL(string: "com.example.app://callback")!
    static let postLogoutRedirectURL = URL(string: "com.example.app://logout-callback")!

    static let clientID = "test-client-id"
    static let clientSecret = "test-client-secret"

    static var configuration: ServiceConfiguration {
        ServiceConfiguration(
            issuer: issuer,
            authorizationEndpoint: authEndpoint,
            tokenEndpoint: tokenEndpoint,
            userinfoEndpoint: userinfoEndpoint,
            registrationEndpoint: registrationEndpoint,
            endSessionEndpoint: endSessionEndpoint,
            deviceAuthorizationEndpoint: deviceEndpoint
        )
    }

    static var tokenResponseJSON: String {
        """
        {
            "access_token": "test-access-token",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "test-refresh-token",
            "scope": "openid profile",
            "id_token": "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyMTIzIiwiZXhwIjoxNzAwMDAwMDAwfQ.fake-signature"
        }
        """
    }
}
