import Testing
import Foundation
import HTTPTypes
@testable import AppAuth

@Suite("TokenService Tests")
struct TokenServiceTests {
    @Test("Token exchange sends correct request")
    func tokenExchange() async throws {
        let recorder = RecordingHTTPClient(
            responseData: Data(TestFixtures.tokenResponseJSON.utf8)
        )
        let service = TokenService(httpClient: recorder)

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

        let tokenResponse = try await service.exchangeCode(from: authResponse)

        #expect(tokenResponse.accessToken == "test-access-token")
        #expect(tokenResponse.refreshToken == "test-refresh-token")

        // Verify the request was sent correctly
        let requests = recorder.recordedRequests
        #expect(requests.count == 1)
        #expect(requests[0].request.method == .post)
        #expect(requests[0].request.headerFields[.contentType] == "application/x-www-form-urlencoded")
    }

    @Test("Token refresh sends correct request")
    func tokenRefresh() async throws {
        let recorder = RecordingHTTPClient(
            responseData: Data(TestFixtures.tokenResponseJSON.utf8)
        )
        let service = TokenService(httpClient: recorder)

        let tokenResponse = try await service.refreshToken(
            configuration: TestFixtures.configuration,
            clientID: TestFixtures.clientID,
            refreshToken: "old-refresh-token"
        )

        #expect(tokenResponse.accessToken == "test-access-token")

        let requests = recorder.recordedRequests
        #expect(requests.count == 1)
        let bodyString = String(data: requests[0].body ?? Data(), encoding: .utf8) ?? ""
        #expect(bodyString.contains("grant_type=refresh_token"))
        #expect(bodyString.contains("refresh_token=old-refresh-token"))
    }

    @Test("Server error throws AuthError")
    func serverError() async {
        let mockClient = MockHTTPClient(
            responseData: Data("Server Error".utf8),
            statusCode: 500
        )
        let service = TokenService(httpClient: mockClient)

        let tokenRequest = TokenRequest(
            configuration: TestFixtures.configuration,
            grantType: .authorizationCode,
            clientID: TestFixtures.clientID,
            authorizationCode: "code"
        )

        await #expect(throws: AuthError.self) {
            try await service.performTokenRequest(tokenRequest)
        }
    }

    @Test("OAuth error in token response throws")
    func oauthErrorResponse() async {
        let errorJSON = """
        {"error": "invalid_grant", "error_description": "Code expired"}
        """
        let mockClient = MockHTTPClient(
            responseData: Data(errorJSON.utf8),
            statusCode: 400
        )
        let service = TokenService(httpClient: mockClient)

        let tokenRequest = TokenRequest(
            configuration: TestFixtures.configuration,
            grantType: .authorizationCode,
            clientID: TestFixtures.clientID,
            authorizationCode: "expired-code"
        )

        await #expect(throws: AuthError.self) {
            try await service.performTokenRequest(tokenRequest)
        }
    }
}
