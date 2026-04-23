/// AppAuth - Pure Swift OpenID Connect / OAuth 2.0 library for iOS 17+ and macOS 14+
///
/// A modern, Swift Concurrency-first implementation of the AppAuth SDK
/// using SwiftUI for authentication flows.
///
/// - On iOS 26+ / macOS 26+: Use ``AuthorizationWebView`` and ``EndSessionWebView``
///   for a rich in-app WebView experience.
/// - On iOS 17+ / macOS 14+: Use ``AuthorizationBrowserView`` and ``EndSessionBrowserView``
///   for a system browser experience via `ASWebAuthenticationSession`.

// MARK: - Models
public typealias _AuthorizationRequest = AuthorizationRequest
public typealias _AuthorizationResponse = AuthorizationResponse
public typealias _TokenRequest = TokenRequest
public typealias _TokenResponse = TokenResponse
public typealias _RegistrationRequest = RegistrationRequest
public typealias _RegistrationResponse = RegistrationResponse
public typealias _EndSessionRequest = EndSessionRequest
public typealias _DeviceAuthorizationRequest = DeviceAuthorizationRequest
public typealias _DeviceAuthorizationResponse = DeviceAuthorizationResponse
