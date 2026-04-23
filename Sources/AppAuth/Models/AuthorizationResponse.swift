import Foundation

/// The response from an OAuth 2.0 authorization request.
public struct AuthorizationResponse: Sendable {
    /// The original authorization request.
    public let request: AuthorizationRequest

    /// The authorization code received from the provider.
    public let authorizationCode: String?

    /// The state value returned by the provider.
    public let state: String?

    /// The access token, if returned directly (implicit flow).
    public let accessToken: String?

    /// The token type, if returned directly (implicit flow).
    public let tokenType: String?

    /// Additional parameters from the response.
    public let additionalParameters: [String: String]

    /// Parses an authorization response from a redirect URL.
    public static func from(
        redirectURL: URL,
        request: AuthorizationRequest
    ) throws -> AuthorizationResponse {
        guard let components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidRedirectURI
        }

        // Check for query parameters (code flow) or fragment (implicit flow)
        let params = parseParameters(from: components)

        // Check for OAuth error
        if let errorCode = params["error"] {
            throw AuthError.oauthError(
                code: errorCode,
                description: params["error_description"]
            )
        }

        // Validate state
        let returnedState = params["state"]
        if returnedState != request.state {
            throw AuthError.stateMismatch
        }

        // Extract known parameters
        let knownKeys: Set<String> = [
            "code", "state", "access_token", "token_type",
            "error", "error_description"
        ]
        let additional = params.filter { !knownKeys.contains($0.key) }

        return AuthorizationResponse(
            request: request,
            authorizationCode: params["code"],
            state: returnedState,
            accessToken: params["access_token"],
            tokenType: params["token_type"],
            additionalParameters: additional
        )
    }

    private static func parseParameters(from components: URLComponents) -> [String: String] {
        var params: [String: String] = [:]

        // Try query parameters first (standard code flow)
        if let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }

        // Also parse fragment for implicit flow
        if let fragment = components.fragment {
            let fragmentItems = fragment
                .split(separator: "&")
                .compactMap { pair -> (String, String)? in
                    let parts = pair.split(separator: "=", maxSplits: 1)
                    guard parts.count == 2 else { return nil }
                    let key = String(parts[0])
                        .removingPercentEncoding ?? String(parts[0])
                    let value = String(parts[1])
                        .removingPercentEncoding ?? String(parts[1])
                    return (key, value)
                }
            for (key, value) in fragmentItems {
                params[key] = value
            }
        }

        return params
    }
}
