import Foundation

/// The response from a device authorization request (RFC 8628).
public struct DeviceAuthorizationResponse: Sendable, Equatable {
    /// The device verification code.
    public let deviceCode: String

    /// The end-user verification code to display to the user.
    public let userCode: String

    /// The end-user verification URI.
    public let verificationURI: URL

    /// The optional complete verification URI including the user code.
    public let verificationURIComplete: URL?

    /// The lifetime in seconds of the device code and user code.
    public let expiresIn: Int

    /// The minimum polling interval in seconds.
    public let interval: Int

    /// The date/time when the device code expires.
    public let expirationDate: Date

    /// Parses a device authorization response from JSON data.
    public static func from(data: Data) throws -> DeviceAuthorizationResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Check for OAuth error
        if let errorCode = json["error"] as? String {
            throw AuthError.oauthError(
                code: errorCode,
                description: json["error_description"] as? String
            )
        }

        guard let deviceCode = json["device_code"] as? String,
              let userCode = json["user_code"] as? String,
              let verificationURIString = json["verification_uri"] as? String,
              let verificationURI = URL(string: verificationURIString),
              let expiresIn = json["expires_in"] as? Int
        else {
            throw AuthError.unexpected("Missing required fields in device authorization response")
        }

        var verificationURIComplete: URL?
        if let completeString = json["verification_uri_complete"] as? String {
            verificationURIComplete = URL(string: completeString)
        }

        let interval = json["interval"] as? Int ?? 5

        return DeviceAuthorizationResponse(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURI: verificationURI,
            verificationURIComplete: verificationURIComplete,
            expiresIn: expiresIn,
            interval: interval,
            expirationDate: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }

    /// Whether the device code has expired.
    public var isExpired: Bool {
        Date() > expirationDate
    }
}
