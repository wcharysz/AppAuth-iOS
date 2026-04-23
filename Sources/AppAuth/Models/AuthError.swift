import Foundation

/// Errors that can occur during OpenID Connect / OAuth 2.0 operations.
public enum AuthError: Error, Sendable, Equatable {
    /// The server returned an OAuth error response.
    case oauthError(code: String, description: String?)

    /// A network error occurred.
    case networkError(URLError)

    /// The server returned an unexpected HTTP status code.
    case serverError(statusCode: Int, data: Data)

    /// The authorization flow was cancelled by the user.
    case userCancelled

    /// The state parameter in the response did not match the request.
    case stateMismatch

    /// The redirect URI could not be parsed or did not match.
    case invalidRedirectURI

    /// A required endpoint is missing from the service configuration.
    case missingEndpoint(String)

    /// The token response is missing required fields.
    case invalidTokenResponse

    /// No refresh token is available to perform token refresh.
    case noRefreshToken

    /// The device authorization flow expired before the user authorized.
    case deviceFlowExpired

    /// The device authorization flow is still pending user authorization.
    case deviceFlowPending

    /// The device authorization flow is rate-limited; slow down polling.
    case deviceFlowSlowDown

    /// An unexpected error occurred.
    case unexpected(String)

    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case let (.oauthError(lCode, lDesc), .oauthError(rCode, rDesc)):
            return lCode == rCode && lDesc == rDesc
        case let (.networkError(lErr), .networkError(rErr)):
            return lErr.code == rErr.code
        case let (.serverError(lStatus, lData), .serverError(rStatus, rData)):
            return lStatus == rStatus && lData == rData
        case (.userCancelled, .userCancelled):
            return true
        case (.stateMismatch, .stateMismatch):
            return true
        case (.invalidRedirectURI, .invalidRedirectURI):
            return true
        case let (.missingEndpoint(l), .missingEndpoint(r)):
            return l == r
        case (.invalidTokenResponse, .invalidTokenResponse):
            return true
        case (.noRefreshToken, .noRefreshToken):
            return true
        case (.deviceFlowExpired, .deviceFlowExpired):
            return true
        case (.deviceFlowPending, .deviceFlowPending):
            return true
        case (.deviceFlowSlowDown, .deviceFlowSlowDown):
            return true
        case let (.unexpected(l), .unexpected(r)):
            return l == r
        default:
            return false
        }
    }
}

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .oauthError(code, description):
            if let description { return "OAuth error [\(code)]: \(description)" }
            return "OAuth error: \(code)"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case let .serverError(statusCode, _):
            return "Server returned HTTP \(statusCode)"
        case .userCancelled:
            return "Authorization was cancelled by the user"
        case .stateMismatch:
            return "State parameter mismatch"
        case .invalidRedirectURI:
            return "Invalid redirect URI"
        case let .missingEndpoint(name):
            return "Missing required endpoint: \(name)"
        case .invalidTokenResponse:
            return "Invalid token response"
        case .noRefreshToken:
            return "No refresh token available"
        case .deviceFlowExpired:
            return "Device authorization flow expired"
        case .deviceFlowPending:
            return "Device authorization pending"
        case .deviceFlowSlowDown:
            return "Device authorization rate limited"
        case let .unexpected(message):
            return "Unexpected error: \(message)"
        }
    }
}
