import Testing
import Foundation
@testable import AppAuth

@Suite("ServiceConfiguration Tests")
struct ServiceConfigurationTests {
    @Test("Manual configuration init")
    func manualInit() {
        let config = ServiceConfiguration(
            issuer: URL(string: "https://accounts.example.com")!,
            authorizationEndpoint: URL(string: "https://accounts.example.com/authorize")!,
            tokenEndpoint: URL(string: "https://accounts.example.com/token")!,
            userinfoEndpoint: URL(string: "https://accounts.example.com/userinfo")!,
            registrationEndpoint: URL(string: "https://accounts.example.com/register")!,
            endSessionEndpoint: URL(string: "https://accounts.example.com/logout")!,
            deviceAuthorizationEndpoint: URL(string: "https://accounts.example.com/device")!
        )

        #expect(config.issuer.absoluteString == "https://accounts.example.com")
        #expect(config.authorizationEndpoint.absoluteString == "https://accounts.example.com/authorize")
        #expect(config.tokenEndpoint.absoluteString == "https://accounts.example.com/token")
        #expect(config.userinfoEndpoint?.absoluteString == "https://accounts.example.com/userinfo")
        #expect(config.registrationEndpoint?.absoluteString == "https://accounts.example.com/register")
        #expect(config.endSessionEndpoint?.absoluteString == "https://accounts.example.com/logout")
        #expect(config.deviceAuthorizationEndpoint?.absoluteString == "https://accounts.example.com/device")
    }

    @Test("Minimal configuration without optional endpoints")
    func minimalInit() {
        let config = ServiceConfiguration(
            issuer: URL(string: "https://issuer.example.com")!,
            authorizationEndpoint: URL(string: "https://issuer.example.com/auth")!,
            tokenEndpoint: URL(string: "https://issuer.example.com/token")!
        )

        #expect(config.userinfoEndpoint == nil)
        #expect(config.revocationEndpoint == nil)
        #expect(config.registrationEndpoint == nil)
        #expect(config.endSessionEndpoint == nil)
        #expect(config.deviceAuthorizationEndpoint == nil)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = ServiceConfiguration(
            issuer: URL(string: "https://accounts.example.com")!,
            authorizationEndpoint: URL(string: "https://accounts.example.com/authorize")!,
            tokenEndpoint: URL(string: "https://accounts.example.com/token")!,
            endSessionEndpoint: URL(string: "https://accounts.example.com/logout")!
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ServiceConfiguration.self, from: data)

        #expect(original == decoded)
    }

    @Test("Discovery with mock HTTP client")
    func discoveryWithMock() async throws {
        let discoveryJSON = """
        {
            "issuer": "https://accounts.example.com",
            "authorization_endpoint": "https://accounts.example.com/authorize",
            "token_endpoint": "https://accounts.example.com/token",
            "userinfo_endpoint": "https://accounts.example.com/userinfo",
            "revocation_endpoint": "https://accounts.example.com/revoke",
            "end_session_endpoint": "https://accounts.example.com/logout",
            "device_authorization_endpoint": "https://accounts.example.com/device",
            "registration_endpoint": "https://accounts.example.com/register",
            "scopes_supported": ["openid", "profile", "email"],
            "response_types_supported": ["code"],
            "grant_types_supported": ["authorization_code", "refresh_token"]
        }
        """

        let mockClient = MockHTTPClient(
            responseData: Data(discoveryJSON.utf8),
            statusCode: 200
        )

        let config = try await ServiceConfiguration.discover(
            from: URL(string: "https://accounts.example.com")!,
            using: mockClient
        )

        #expect(config.issuer.absoluteString == "https://accounts.example.com")
        #expect(config.authorizationEndpoint.absoluteString == "https://accounts.example.com/authorize")
        #expect(config.tokenEndpoint.absoluteString == "https://accounts.example.com/token")
        #expect(config.endSessionEndpoint?.absoluteString == "https://accounts.example.com/logout")
        #expect(config.deviceAuthorizationEndpoint?.absoluteString == "https://accounts.example.com/device")
    }

    @Test("Discovery with server error throws")
    func discoveryServerError() async {
        let mockClient = MockHTTPClient(
            responseData: Data("Not Found".utf8),
            statusCode: 404
        )

        await #expect(throws: AuthError.self) {
            try await ServiceConfiguration.discover(
                from: URL(string: "https://bad.example.com")!,
                using: mockClient
            )
        }
    }
}
