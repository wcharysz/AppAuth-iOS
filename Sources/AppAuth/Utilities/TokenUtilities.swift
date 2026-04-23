import Foundation

/// Token parsing and introspection utilities.
public enum TokenUtilities: Sendable {
    /// Decodes the payload of a JWT (JSON Web Token) without verifying the signature.
    /// This is useful for extracting claims from ID tokens for display purposes.
    ///
    /// - Warning: This does NOT validate the token. Always verify tokens server-side
    ///   or use a proper JWT validation library for security-sensitive operations.
    public static func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else { return nil }

        let payloadSegment = String(segments[1])
        guard let payloadData = base64URLDecode(payloadSegment) else { return nil }

        return try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
    }

    /// Extracts the "sub" (subject) claim from a JWT.
    public static func subject(from jwt: String) -> String? {
        decodeJWTPayload(jwt)?["sub"] as? String
    }

    /// Extracts the "exp" (expiration) claim from a JWT.
    public static func expirationDate(from jwt: String) -> Date? {
        guard let exp = decodeJWTPayload(jwt)?["exp"] as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: exp)
    }

    /// Base64url decodes a string (RFC 4648 §5).
    static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Pad with '=' to make length a multiple of 4
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(contentsOf: String(repeating: "=", count: 4 - remainder))
        }

        return Data(base64Encoded: base64)
    }
}
