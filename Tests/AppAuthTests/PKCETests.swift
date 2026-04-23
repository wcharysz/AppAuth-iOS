import Testing
import Foundation
@testable import AppAuth

@Suite("PKCE Tests")
struct PKCETests {
    @Test("Code verifier has correct length")
    func codeVerifierLength() {
        let verifier = PKCE.generateCodeVerifier()
        // 32 bytes -> 43 base64url chars (no padding)
        #expect(verifier.count == 43)
    }

    @Test("Code verifier uses URL-safe characters")
    func codeVerifierCharacters() {
        let verifier = PKCE.generateCodeVerifier()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let allAllowed = verifier.unicodeScalars.allSatisfy { allowed.contains($0) }
        #expect(allAllowed)
    }

    @Test("Code challenge is deterministic for same verifier")
    func codeChallengeDeterministic() {
        let verifier = "test-code-verifier-12345678901234567890"
        let challenge1 = PKCE.generateCodeChallenge(from: verifier)
        let challenge2 = PKCE.generateCodeChallenge(from: verifier)
        #expect(challenge1 == challenge2)
    }

    @Test("Code challenge differs from verifier")
    func codeChallengeNotEqualToVerifier() {
        let verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.generateCodeChallenge(from: verifier)
        #expect(verifier != challenge)
    }

    @Test("State has correct length")
    func stateLength() {
        let state = PKCE.generateState()
        // 16 bytes -> 22 base64url chars (no padding)
        #expect(state.count == 22)
    }

    @Test("State is unique")
    func stateUniqueness() {
        let state1 = PKCE.generateState()
        let state2 = PKCE.generateState()
        #expect(state1 != state2)
    }

    @Test("Base64URL encoding removes padding")
    func base64URLNoPadding() {
        let data = Data([0x01, 0x02, 0x03])
        let encoded = PKCE.base64URLEncode(data)
        #expect(!encoded.contains("="))
        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
    }
}
