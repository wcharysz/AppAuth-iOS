import Testing
import Foundation
@testable import AppAuth

@Suite("TokenUtilities Tests")
struct TokenUtilitiesTests {
    // A test JWT with header.payload.signature
    // Payload: {"sub": "user123", "exp": 1700000000, "name": "Test User"}
    let testJWT: String = {
        let header = #"{"alg":"RS256"}"#
        let payload = #"{"sub":"user123","exp":1700000000,"name":"Test User"}"#

        func base64url(_ str: String) -> String {
            Data(str.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        return "\(base64url(header)).\(base64url(payload)).fake-signature"
    }()

    @Test("Decode JWT payload")
    func decodePayload() {
        let payload = TokenUtilities.decodeJWTPayload(testJWT)

        #expect(payload != nil)
        #expect(payload?["sub"] as? String == "user123")
        #expect(payload?["name"] as? String == "Test User")
    }

    @Test("Extract subject from JWT")
    func extractSubject() {
        let subject = TokenUtilities.subject(from: testJWT)
        #expect(subject == "user123")
    }

    @Test("Extract expiration date from JWT")
    func extractExpiration() {
        let expDate = TokenUtilities.expirationDate(from: testJWT)
        #expect(expDate != nil)
        #expect(expDate == Date(timeIntervalSince1970: 1700000000))
    }

    @Test("Invalid JWT returns nil")
    func invalidJWT() {
        #expect(TokenUtilities.decodeJWTPayload("not-a-jwt") == nil)
        #expect(TokenUtilities.subject(from: "invalid") == nil)
        #expect(TokenUtilities.expirationDate(from: "") == nil)
    }

    @Test("Base64URL decode with padding")
    func base64URLDecode() {
        // "hello" in base64url
        let encoded = "aGVsbG8"
        let decoded = TokenUtilities.base64URLDecode(encoded)
        #expect(decoded != nil)
        #expect(String(data: decoded!, encoding: .utf8) == "hello")
    }
}
