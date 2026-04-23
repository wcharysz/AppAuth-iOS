import Testing
import Foundation
@testable import AppAuth

@Suite("GrantType Tests")
struct GrantTypeTests {
    @Test("Standard grant types have correct raw values")
    func standardGrantTypes() {
        #expect(GrantType.authorizationCode.rawValue == "authorization_code")
        #expect(GrantType.implicit.rawValue == "implicit")
        #expect(GrantType.clientCredentials.rawValue == "client_credentials")
        #expect(GrantType.refreshToken.rawValue == "refresh_token")
        #expect(GrantType.deviceCode.rawValue == "urn:ietf:params:oauth:grant-type:device_code")
    }

    @Test("Custom grant type")
    func customGrantType() {
        let custom = GrantType(rawValue: "custom_grant")
        #expect(custom.rawValue == "custom_grant")
    }

    @Test("Equality")
    func equality() {
        #expect(GrantType.authorizationCode == GrantType(rawValue: "authorization_code"))
        #expect(GrantType.authorizationCode != GrantType.refreshToken)
    }
}

@Suite("ResponseType Tests")
struct ResponseTypeTests {
    @Test("Standard response types have correct raw values")
    func standardResponseTypes() {
        #expect(ResponseType.code.rawValue == "code")
        #expect(ResponseType.token.rawValue == "token")
        #expect(ResponseType.idToken.rawValue == "id_token")
    }
}

@Suite("Scope Tests")
struct ScopeTests {
    @Test("Standard scopes have correct raw values")
    func standardScopes() {
        #expect(Scope.openID.rawValue == "openid")
        #expect(Scope.profile.rawValue == "profile")
        #expect(Scope.email.rawValue == "email")
        #expect(Scope.address.rawValue == "address")
        #expect(Scope.phone.rawValue == "phone")
        #expect(Scope.offlineAccess.rawValue == "offline_access")
    }

    @Test("Scope string from array")
    func scopeString() {
        let scopes: [Scope] = [.openID, .profile, .email]
        #expect(Scope.scopeString(from: scopes) == "openid profile email")
    }

    @Test("Empty scope array produces empty string")
    func emptyScopeString() {
        #expect(Scope.scopeString(from: []) == "")
    }
}
