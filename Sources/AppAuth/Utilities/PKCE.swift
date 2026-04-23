import Foundation
import CryptoKit

/// PKCE (Proof Key for Code Exchange) utilities for OAuth 2.0 (RFC 7636).
public enum PKCE: Sendable {
    /// The length of the code verifier in bytes (before base64 encoding).
    private static let codeVerifierByteLength = 32

    /// The length of the state parameter in bytes (before base64 encoding).
    private static let stateByteLength = 16

    /// Generates a cryptographically random code verifier.
    public static func generateCodeVerifier() -> String {
        base64URLEncode(Data(randomBytes(count: codeVerifierByteLength)))
    }

    /// Generates a code challenge from a code verifier using S256.
    public static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return base64URLEncode(Data(hash))
    }

    /// Generates a cryptographically random state parameter.
    public static func generateState() -> String {
        base64URLEncode(Data(randomBytes(count: stateByteLength)))
    }

    /// Base64url encodes data (RFC 4648 §5).
    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func randomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        precondition(status == errSecSuccess, "Failed to generate random bytes")
        return bytes
    }
}
