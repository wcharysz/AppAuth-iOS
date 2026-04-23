import Testing
import Foundation
@testable import AppAuth

@Suite("DiscoveryDocument Tests")
struct DiscoveryDocumentTests {
    @Test("Parse full discovery document")
    func parseFullDocument() throws {
        let json = """
        {
            "issuer": "https://accounts.example.com",
            "authorization_endpoint": "https://accounts.example.com/authorize",
            "token_endpoint": "https://accounts.example.com/token",
            "userinfo_endpoint": "https://accounts.example.com/userinfo",
            "jwks_uri": "https://accounts.example.com/.well-known/jwks.json",
            "registration_endpoint": "https://accounts.example.com/register",
            "scopes_supported": ["openid", "profile", "email"],
            "response_types_supported": ["code", "token"],
            "grant_types_supported": ["authorization_code", "refresh_token"],
            "subject_types_supported": ["public"],
            "id_token_signing_alg_values_supported": ["RS256"],
            "token_endpoint_auth_methods_supported": ["client_secret_post"],
            "revocation_endpoint": "https://accounts.example.com/revoke",
            "end_session_endpoint": "https://accounts.example.com/logout",
            "device_authorization_endpoint": "https://accounts.example.com/device"
        }
        """

        let document = try JSONDecoder().decode(DiscoveryDocument.self, from: Data(json.utf8))

        #expect(document.issuer.absoluteString == "https://accounts.example.com")
        #expect(document.authorizationEndpoint.absoluteString == "https://accounts.example.com/authorize")
        #expect(document.tokenEndpoint.absoluteString == "https://accounts.example.com/token")
        #expect(document.scopesSupported == ["openid", "profile", "email"])
        #expect(document.responseTypesSupported == ["code", "token"])
        #expect(document.endSessionEndpoint?.absoluteString == "https://accounts.example.com/logout")
        #expect(document.deviceAuthorizationEndpoint?.absoluteString == "https://accounts.example.com/device")
    }

    @Test("Convert to ServiceConfiguration")
    func convertToServiceConfiguration() throws {
        let json = """
        {
            "issuer": "https://accounts.example.com",
            "authorization_endpoint": "https://accounts.example.com/authorize",
            "token_endpoint": "https://accounts.example.com/token",
            "end_session_endpoint": "https://accounts.example.com/logout"
        }
        """

        let document = try JSONDecoder().decode(DiscoveryDocument.self, from: Data(json.utf8))
        let config = document.asServiceConfiguration()

        #expect(config.issuer == document.issuer)
        #expect(config.authorizationEndpoint == document.authorizationEndpoint)
        #expect(config.tokenEndpoint == document.tokenEndpoint)
        #expect(config.endSessionEndpoint == document.endSessionEndpoint)
        #expect(config.deviceAuthorizationEndpoint == nil)
    }

    @Test("Minimal discovery document")
    func minimalDocument() throws {
        let json = """
        {
            "issuer": "https://issuer.example.com",
            "authorization_endpoint": "https://issuer.example.com/auth",
            "token_endpoint": "https://issuer.example.com/token"
        }
        """

        let document = try JSONDecoder().decode(DiscoveryDocument.self, from: Data(json.utf8))

        #expect(document.userinfoEndpoint == nil)
        #expect(document.registrationEndpoint == nil)
        #expect(document.endSessionEndpoint == nil)
    }
}
