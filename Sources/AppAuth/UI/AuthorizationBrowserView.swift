import SwiftUI
import AuthenticationServices

/// A SwiftUI view that presents the OAuth 2.0 authorization flow using the system browser
/// via `ASWebAuthenticationSession`.
///
/// Available on iOS 17+ and macOS 14+ (Sonoma). On iOS 26+ / macOS 26+, consider using
/// ``AuthorizationWebView`` for an in-app WebView experience.
///
/// Usage:
/// ```swift
/// AuthorizationBrowserView(request: authRequest) { result in
///     switch result {
///     case .success(let response):
///         // Exchange code for tokens
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
public struct AuthorizationBrowserView: View {
    private let request: AuthorizationRequest
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @Sendable (Result<AuthorizationResponse, AuthError>) -> Void

    @State private var hasStarted = false

    /// Creates an authorization browser view.
    /// - Parameters:
    ///   - request: The authorization request to present.
    ///   - prefersEphemeralWebBrowserSession: When `true`, the browser session does not share
    ///     cookies or data with the user's normal browser session. Defaults to `false`.
    ///   - onCompletion: Called with the authorization response or error.
    public init(
        request: AuthorizationRequest,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @Sendable (Result<AuthorizationResponse, AuthError>) -> Void
    ) {
        self.request = request
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    public var body: some View {
        ProgressView("Signing in…")
            .task {
                guard !hasStarted else { return }
                hasStarted = true
                await startSession()
            }
    }

    private func startSession() async {
        let url = request.authorizationURL
        let callbackScheme = request.redirectURL.scheme

        do {
            let callbackURL = try await performAuthentication(url: url, callbackScheme: callbackScheme)
            let response = try AuthorizationResponse.from(redirectURL: callbackURL, request: request)
            onCompletion(.success(response))
        } catch let error as AuthError {
            onCompletion(.failure(error))
        } catch {
            onCompletion(.failure(.unexpected(error.localizedDescription)))
        }
    }

    private func performAuthentication(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                    {
                        continuation.resume(throwing: AuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: AuthError.unexpected(error.localizedDescription))
                    }
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: AuthError.userCancelled)
                }
            }
            session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
            session.start()
        }
    }
}

// MARK: - Full Authorization Flow View (Browser)

/// A convenience SwiftUI view that handles the complete authorization code + token exchange flow
/// using the system browser via `ASWebAuthenticationSession`.
///
/// Available on iOS 17+ and macOS 14+. On iOS 26+ / macOS 26+, consider using
/// ``AuthorizationFlowView`` for an in-app WebView experience.
///
/// Usage:
/// ```swift
/// AuthorizationBrowserFlowView(
///     request: authRequest,
///     authState: authState
/// ) { result in
///     switch result {
///     case .success:
///         // User is authenticated, tokens are in authState
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
public struct AuthorizationBrowserFlowView: View {
    private let request: AuthorizationRequest
    private let authState: AuthState
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @Sendable (Result<Void, AuthError>) -> Void

    @State private var isExchangingToken = false

    /// Creates a full authorization flow browser view.
    /// - Parameters:
    ///   - request: The authorization request.
    ///   - authState: The auth state to update with tokens.
    ///   - prefersEphemeralWebBrowserSession: When `true`, the browser session does not share
    ///     cookies or data with the user's normal browser session. Defaults to `false`.
    ///   - onCompletion: Called when the flow completes or fails.
    public init(
        request: AuthorizationRequest,
        authState: AuthState,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @Sendable (Result<Void, AuthError>) -> Void
    ) {
        self.request = request
        self.authState = authState
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    public var body: some View {
        ZStack {
            AuthorizationBrowserView(
                request: request,
                prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession
            ) { result in
                Task {
                    switch result {
                    case .success(let authResponse):
                        await setIsExchangingToken(true)
                        await exchangeCode(authResponse: authResponse)
                    case .failure(let error):
                        await authState.setError(error)
                        onCompletion(.failure(error))
                    }
                }
            }

            if isExchangingToken {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Completing sign in…")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func setIsExchangingToken(_ value: Bool) {
        isExchangingToken = value
    }

    private func exchangeCode(authResponse: AuthorizationResponse) async {
        let service = AuthorizationService()
        do {
            guard authResponse.authorizationCode != nil else {
                throw AuthError.unexpected("No authorization code")
            }
            let tokenRequest = TokenRequest.exchangeCode(from: authResponse)
            let tokenResponse = try await service.performTokenRequest(tokenRequest)
            authState.update(authorizationResponse: authResponse, tokenResponse: tokenResponse)
            isExchangingToken = false
            onCompletion(.success(()))
        } catch let error as AuthError {
            authState.setError(error)
            isExchangingToken = false
            onCompletion(.failure(error))
        } catch {
            let authError = AuthError.unexpected(error.localizedDescription)
            authState.setError(authError)
            isExchangingToken = false
            onCompletion(.failure(authError))
        }
    }
}
