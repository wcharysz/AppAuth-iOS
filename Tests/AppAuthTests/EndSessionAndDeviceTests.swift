import Testing
import Foundation
@testable import AppAuth

@Suite("EndSessionRequest Tests")
struct EndSessionRequestTests {
    @Test("End session URL contains required parameters")
    func endSessionURL() throws {
        let request = EndSessionRequest(
            configuration: TestFixtures.configuration,
            idTokenHint: "test-id-token",
            postLogoutRedirectURL: TestFixtures.postLogoutRedirectURL
        )

        let url = try request.endSessionURL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryDict = Dictionary(
            (components.queryItems ?? []).map { ($0.name, $0.value ?? "") },
            uniquingKeysWith: { _, last in last }
        )

        #expect(queryDict["id_token_hint"] == "test-id-token")
        #expect(queryDict["post_logout_redirect_uri"] == TestFixtures.postLogoutRedirectURL.absoluteString)
        #expect(queryDict["state"] == request.state)
    }

    @Test("Missing end session endpoint throws")
    func missingEndpoint() {
        let config = ServiceConfiguration(
            issuer: TestFixtures.issuer,
            authorizationEndpoint: TestFixtures.authEndpoint,
            tokenEndpoint: TestFixtures.tokenEndpoint
            // No endSessionEndpoint
        )

        let request = EndSessionRequest(configuration: config)

        #expect(throws: AuthError.self) {
            _ = try request.endSessionURL
        }
    }
}

@Suite("DeviceAuthorizationResponse Tests")
struct DeviceAuthorizationResponseTests {
    @Test("Parse device authorization response")
    func parseResponse() throws {
        let json = """
        {
            "device_code": "device-code-123",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://accounts.example.com/device",
            "verification_uri_complete": "https://accounts.example.com/device?user_code=ABCD-EFGH",
            "expires_in": 1800,
            "interval": 5
        }
        """

        let response = try DeviceAuthorizationResponse.from(data: Data(json.utf8))

        #expect(response.deviceCode == "device-code-123")
        #expect(response.userCode == "ABCD-EFGH")
        #expect(response.verificationURI.absoluteString == "https://accounts.example.com/device")
        #expect(response.verificationURIComplete?.absoluteString == "https://accounts.example.com/device?user_code=ABCD-EFGH")
        #expect(response.expiresIn == 1800)
        #expect(response.interval == 5)
        #expect(!response.isExpired)
    }

    @Test("Default interval when not specified")
    func defaultInterval() throws {
        let json = """
        {
            "device_code": "code",
            "user_code": "CODE",
            "verification_uri": "https://example.com/device",
            "expires_in": 600
        }
        """

        let response = try DeviceAuthorizationResponse.from(data: Data(json.utf8))
        #expect(response.interval == 5)
    }
}

@Suite("RegistrationResponse Tests")
struct RegistrationResponseTests {
    @Test("Parse registration response")
    func parseResponse() throws {
        let json = """
        {
            "client_id": "new-client-id",
            "client_secret": "new-client-secret",
            "client_secret_expires_at": 1700000000,
            "client_id_issued_at": 1699000000,
            "registration_access_token": "reg-token",
            "registration_client_uri": "https://accounts.example.com/register/new-client-id",
            "token_endpoint_auth_method": "client_secret_post"
        }
        """

        let response = try RegistrationResponse.from(data: Data(json.utf8))

        #expect(response.clientID == "new-client-id")
        #expect(response.clientSecret == "new-client-secret")
        #expect(response.clientSecretExpiresAt != nil)
        #expect(response.registrationAccessToken == "reg-token")
        #expect(response.tokenEndpointAuthMethod == "client_secret_post")
    }

    @Test("Missing client_id throws")
    func missingClientID() {
        let json = """
        {
            "client_secret": "secret"
        }
        """

        #expect(throws: AuthError.self) {
            try RegistrationResponse.from(data: Data(json.utf8))
        }
    }
}
