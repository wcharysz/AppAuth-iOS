import Foundation

/// A device authorization request (RFC 8628).
public struct DeviceAuthorizationRequest: Sendable {
    /// The service configuration for the provider.
    public let configuration: ServiceConfiguration

    /// The client identifier.
    public let clientID: String

    /// The client secret, if applicable.
    public let clientSecret: String?

    /// The requested scopes.
    public let scopes: [Scope]

    /// Additional parameters to include in the request.
    public let additionalParameters: [String: String]

    public init(
        configuration: ServiceConfiguration,
        clientID: String,
        clientSecret: String? = nil,
        scopes: [Scope] = [.openID],
        additionalParameters: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.scopes = scopes
        self.additionalParameters = additionalParameters
    }

    /// Builds the URL-encoded form body for the device authorization request.
    public var httpBody: Data {
        var params: [(String, String)] = [
            ("client_id", clientID),
        ]

        if let clientSecret { params.append(("client_secret", clientSecret)) }

        let scopeString = Scope.scopeString(from: scopes)
        if !scopeString.isEmpty {
            params.append(("scope", scopeString))
        }

        for (key, value) in additionalParameters.sorted(by: { $0.key < $1.key }) {
            params.append((key, value))
        }

        let body = params
            .map { "\(URLQueryBuilder.percentEncode($0.0))=\(URLQueryBuilder.percentEncode($0.1))" }
            .joined(separator: "&")
        return Data(body.utf8)
    }
}
