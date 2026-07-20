# AppAuth for iOS and macOS

[![tests](https://github.com/openid/AppAuth-iOS/actions/workflows/tests.yml/badge.svg?event=push)](https://github.com/openid/AppAuth-iOS/actions/workflows/tests.yml)
[![codecov](https://codecov.io/gh/openid/AppAuth-iOS/branch/master/graph/badge.svg)](https://codecov.io/gh/openid/AppAuth-iOS)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

A pure-Swift [OAuth 2.0](https://tools.ietf.org/html/rfc6749) and [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) client library for iOS 17+ and macOS 14+.

Built with Swift 6 strict concurrency, Swift Concurrency (`async`/`await`, actors), and SwiftUI-first authentication views. No external dependencies.

## Features

- **OpenID Connect Discovery** — automatic `.well-known/openid-configuration` fetching
- **Authorization Code Flow with PKCE** — [RFC 7636](https://tools.ietf.org/html/rfc7636) enabled by default
- **Token Exchange & Refresh** — automatic code exchange, token refresh, and client credentials
- **Device Authorization Grant** — [RFC 8628](https://tools.ietf.org/html/rfc8628) with polling and backoff
- **Dynamic Client Registration** — [RFC 7591](https://tools.ietf.org/html/rfc7591)
- **RP-Initiated Logout** — OpenID Connect end-session support
- **SwiftUI Views** — drop-in views for login and logout flows
- **Observable Auth State** — `@Observable` `AuthState` for SwiftUI data binding
- **Token Persistence** — `TokenStorage` protocol for custom persistence (Keychain, etc.)
- **Testable** — `HTTPClient` protocol for dependency injection and mocking

## Platforms

| Platform | Minimum Version | Auth UI |
|----------|----------------|---------|
| iOS 17+  | `ASWebAuthenticationSession` (system browser) | `AuthorizationBrowserFlowView` |
| iOS 26+  | In-app `WebView` (WebKit SwiftUI API) | `AuthorizationFlowView` |
| macOS 14+ | `ASWebAuthenticationSession` (system browser) | `AuthorizationBrowserFlowView` |

## Installation

### Swift Package Manager

Add AppAuth as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/openid/AppAuth-iOS.git", branch: "iOS26")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Quick Start

### 1. Configure the Provider

Discover endpoints automatically from an OpenID Connect issuer:

```swift
import AppAuth

let issuer = URL(string: "https://accounts.example.com")!
let configuration = try await ServiceConfiguration.discover(from: issuer)
```

Or specify endpoints manually:

```swift
let configuration = ServiceConfiguration(
    issuer: URL(string: "https://accounts.example.com")!,
    authorizationEndpoint: URL(string: "https://accounts.example.com/authorize")!,
    tokenEndpoint: URL(string: "https://accounts.example.com/token")!
)
```

### 2. Build an Authorization Request

```swift
let request = AuthorizationRequest(
    configuration: configuration,
    clientID: "your-client-id",
    scopes: [.openID, .profile, .email],
    redirectURL: URL(string: "com.example.app://oauth/callback")!
)
```

PKCE is enabled by default. The `state`, `codeVerifier`, and `codeChallenge` are generated automatically.

### 3. Present the Login Flow (SwiftUI)

#### iOS 26+ — In-App WebView

Use `AuthorizationFlowView` for a full in-app experience. It handles the authorization request, code exchange, and token storage in a single view:

```swift
import SwiftUI
import AppAuth

struct LoginView: View {
    @State private var authState = AuthState()
    @State private var showLogin = false

    var body: some View {
        Button("Sign In") { showLogin = true }
            .sheet(isPresented: $showLogin) {
                AuthorizationFlowView(
                    request: { try await buildAuthRequest() },
                    authState: authState,
                    prefersEphemeralWebBrowserSession: true
                ) { result in
                    switch result {
                    case .success(let tokenResponse):
                        // Optional: inspect tokenResponse directly
                        print("Access token expires in: \(tokenResponse.expiresIn ?? 0)s")
                    case .failure(let error):
                        print("Sign-in failed: \(error)")
                    }
                    showLogin = false
                }
            }
    }
}
```

The async request closure is useful when you need to perform OpenID Connect discovery before building the request.

#### iOS 17+ / macOS 14+ — System Browser

Use `AuthorizationBrowserFlowView` for a system browser experience via `ASWebAuthenticationSession`:

```swift
AuthorizationBrowserFlowView(
    request: authRequest,
    authState: authState,
    prefersEphemeralWebBrowserSession: true
) { result in
    switch result {
    case .success(let tokenResponse):
        // Optional: inspect tokenResponse directly
        print("Received access token: \(tokenResponse.accessToken.prefix(8))...")
    case .failure(let error):
        print("Sign-in failed: \(error)")
    }
    showLogin = false
}
```

Both flow views accept either a synchronous `AuthorizationRequest` or an `async throws` closure that produces one.

### 4. Use Tokens

After a successful login, tokens are available on the `AuthState` object:

```swift
if authState.isAuthorized {
    let accessToken = authState.accessToken
    let idToken = authState.idToken
}
```

#### Making API Calls with Fresh Tokens

Use `performAction(freshTokens:)` to automatically refresh expired tokens before making API calls:

```swift
try await authState.performAction { accessToken, idToken in
    var request = URLRequest(url: apiEndpoint)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)
    // handle response...
}
```

### 5. Logout

#### iOS 26+ — In-App WebView

```swift
LogoutFlowView(
    request: endSessionRequest,
    authState: authState
) { result in
    showLogout = false
}
```

#### iOS 17+ / macOS 14+ — System Browser

```swift
LogoutBrowserFlowView(
    request: endSessionRequest,
    authState: authState
) { result in
    showLogout = false
}
```

Build the `EndSessionRequest`:

```swift
let endSessionRequest = EndSessionRequest(
    configuration: configuration,
    idTokenHint: authState.idToken ?? "",
    postLogoutRedirectURL: URL(string: "com.example.app://oauth/logout")!
)
```

## Architecture

### Models

| Type | Description |
|------|-------------|
| `ServiceConfiguration` | Provider endpoints (authorization, token, userinfo, etc.) |
| `AuthorizationRequest` | Authorization code request with PKCE |
| `AuthorizationResponse` | Parsed authorization redirect (code, state) |
| `TokenRequest` | Token endpoint request (code exchange, refresh, client credentials) |
| `TokenResponse` | Parsed token response (access, refresh, ID tokens) |
| `EndSessionRequest` | RP-initiated logout request |
| `RegistrationRequest` / `RegistrationResponse` | Dynamic client registration |
| `DeviceAuthorizationRequest` / `DeviceAuthorizationResponse` | Device flow |
| `AuthError` | Typed errors for all OAuth/OIDC failure modes |
| `Scope` | Standard OIDC scopes (`.openID`, `.profile`, `.email`, etc.) |
| `GrantType` | Grant types (`.authorizationCode`, `.refreshToken`, `.clientCredentials`, `.deviceCode`) |
| `ResponseType` | Response types (`.code`, `.token`, `.idToken`) |

### Services

All services are Swift actors and accept an `HTTPClient` for dependency injection.

| Service | Description |
|---------|-------------|
| `AuthorizationService` | High-level: redirect handling, token refresh, client credentials |
| `TokenService` | Low-level: code exchange, token refresh, client credentials POST requests |
| `RegistrationService` | Dynamic client registration |
| `DeviceAuthorizationService` | Device authorization + token polling with backoff |

### State

| Type | Description |
|------|-------------|
| `AuthState` | `@Observable` `@MainActor` class — central source of truth for auth state in SwiftUI |
| `TokenStorage` | Protocol for custom persistence (Keychain, UserDefaults, etc.) |
| `AuthStateData` | `Codable` struct for serializing/restoring auth state |

### SwiftUI Views

| View | Platform | Description |
|------|----------|-------------|
| `AuthorizationFlowView` | iOS 26+ | In-app WebView login with automatic token exchange |
| `AuthorizationBrowserFlowView` | iOS 17+ / macOS 14+ | System browser login with automatic token exchange |
| `AuthorizationWebView` | iOS 26+ | In-app WebView for authorization only (no token exchange) |
| `AuthorizationBrowserView` | iOS 17+ / macOS 14+ | System browser for authorization only |
| `LogoutFlowView` | iOS 26+ | In-app WebView logout with state clearing |
| `LogoutBrowserFlowView` | iOS 17+ / macOS 14+ | System browser logout with state clearing |
| `EndSessionWebView` | iOS 26+ | In-app WebView for end session only |
| `EndSessionBrowserView` | iOS 17+ / macOS 14+ | System browser for end session only |

### Utilities

| Type | Description |
|------|-------------|
| `HTTPClient` | Protocol wrapping `URLSession.data(for:)` — inject mocks for testing |
| `PKCE` | Code verifier, challenge (S256), and state generation |
| `TokenUtilities` | JWT payload decoding (without verification) |

## Advanced Usage

### Custom HTTP Client

All services and `AuthState` accept an `HTTPClient` parameter. Provide a custom implementation for testing, logging, or certificate pinning:

```swift
struct LoggingHTTPClient: HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        print("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("← \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        return (data, response)
    }
}

let authState = AuthState(httpClient: LoggingHTTPClient())
let config = try await ServiceConfiguration.discover(from: issuer, using: LoggingHTTPClient())
```

### Token Persistence

Implement the `TokenStorage` protocol to persist auth state across app launches:

```swift
struct KeychainTokenStorage: TokenStorage {
    func save(_ data: AuthStateData) async throws {
        let encoded = try JSONEncoder().encode(data)
        // save to Keychain...
    }

    func load() async throws -> AuthStateData? {
        // load from Keychain...
    }

    func clear() async throws {
        // remove from Keychain...
    }
}
```

Serialize and restore `AuthState`:

```swift
// Save
if let data = authState.exportStateData() {
    try await storage.save(data)
}

// Restore
if let data = try await storage.load() {
    authState.restore(from: data, configuration: configuration)
}
```

### Device Authorization Flow

For devices without a browser (e.g., tvOS-like scenarios):

```swift
let service = DeviceAuthorizationService()

let request = DeviceAuthorizationRequest(
    configuration: configuration,
    clientID: "your-client-id",
    scopes: [.openID, .profile]
)

// Step 1: Get the user code
let deviceResponse = try await service.authorize(request)
print("Go to \(deviceResponse.verificationURI) and enter: \(deviceResponse.userCode)")

// Step 2: Poll for token (blocks until user authorizes or timeout)
let tokenResponse = try await service.pollForToken(
    deviceResponse: deviceResponse,
    clientID: "your-client-id",
    configuration: configuration
)
```

### Ephemeral Sessions

Set `prefersEphemeralWebBrowserSession: true` on any flow view to prevent cookie/session sharing with the user's browser. This forces a fresh login every time:

```swift
AuthorizationFlowView(
    request: authRequest,
    authState: authState,
    prefersEphemeralWebBrowserSession: true  // no shared cookies
) { result in
    switch result {
    case .success(let tokenResponse):
        print("Signed in with token type: \(tokenResponse.tokenType)")
    case .failure(let error):
        print("Sign-in failed: \(error)")
    }
}
```

## License

AppAuth is licensed under the [Apache License 2.0](LICENSE).