import Foundation
import HTTPTypes

/// Service for performing the OAuth 2.0 Device Authorization Grant (RFC 8628).
public actor DeviceAuthorizationService {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = LoggingHTTPClient()) {
        self.httpClient = httpClient
    }

    /// Initiates a device authorization flow.
    public func authorize(
        _ request: DeviceAuthorizationRequest
    ) async throws -> DeviceAuthorizationResponse {
        guard let endpoint = request.configuration.deviceAuthorizationEndpoint else {
            throw AuthError.missingEndpoint("device_authorization_endpoint")
        }

        var urlRequest = HTTPRequest(method: .post, url: endpoint)
        urlRequest.headerFields[.contentType] = "application/x-www-form-urlencoded"

        let (data, response) = try await httpClient.data(for: urlRequest, body: request.httpBody)

          guard response.status.kind == .successful else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorCode = json["error"] as? String
            {
                throw AuthError.oauthError(
                    code: errorCode,
                    description: json["error_description"] as? String
                )
            }
            throw AuthError.serverError(statusCode: response.status.code, data: data)
        }

        return try DeviceAuthorizationResponse.from(data: data)
    }

    /// Polls the token endpoint until the user authorizes, the flow expires, or an error occurs.
    public func pollForToken(
        deviceResponse: DeviceAuthorizationResponse,
        clientID: String,
        clientSecret: String? = nil,
        configuration: ServiceConfiguration
    ) async throws -> TokenResponse {
        let tokenService = TokenService(httpClient: httpClient)
        var interval = deviceResponse.interval

        while !deviceResponse.isExpired {
            try await Task.sleep(for: .seconds(interval))

            let tokenRequest = TokenRequest(
                configuration: configuration,
                grantType: .deviceCode,
                clientID: clientID,
                clientSecret: clientSecret,
                additionalParameters: ["device_code": deviceResponse.deviceCode]
            )

            do {
                return try await tokenService.performTokenRequest(tokenRequest)
            } catch let AuthError.oauthError(code, _) {
                switch code {
                case "authorization_pending":
                    continue
                case "slow_down":
                    interval += 5
                    continue
                default:
                    throw AuthError.oauthError(code: code, description: nil)
                }
            }
        }

        throw AuthError.deviceFlowExpired
    }
}
