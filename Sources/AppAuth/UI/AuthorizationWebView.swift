// WebKit SwiftUI views (WebView, WebPage) require iOS 26+.
// Guarded with #if os(iOS) to work around a macOS SDK swiftinterface bug
// where AsyncSequence<Element, Failure> typed throws lack proper availability annotations.
// On macOS, use AuthorizationBrowserView / AuthorizationBrowserFlowView instead.
#if os(iOS)
import SwiftUI
import WebKit

/// A SwiftUI view that presents the OAuth 2.0 authorization flow in an in-app WebView.
///
/// Uses the iOS 26 / macOS 26 WebKit SwiftUI API (`WebView` + `WebPage`) to display
/// the provider's login/consent page and intercept the redirect.
///
/// For iOS 17–25 / macOS 14–25, use ``AuthorizationBrowserView`` instead, which uses
/// `ASWebAuthenticationSession` to present the authorization flow in a system browser.
///
/// Usage:
/// ```swift
/// AuthorizationWebView(request: authRequest) { result in
///     switch result {
///     case .success(let response):
///         // Exchange code for tokens
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
public struct AuthorizationWebView: View {
    private let request: AuthorizationRequest
    private let onCompletion: @Sendable (Result<AuthorizationResponse, AuthError>) -> Void

    @State private var page: WebPage
    @State private var isLoading = true
    @State private var hasCompleted = false

    /// Creates an authorization web view.
    /// - Parameters:
    ///   - request: The authorization request to present.
    ///   - prefersEphemeralWebBrowserSession: When `true`, uses a non-persistent
    ///     `WKWebsiteDataStore` so cookies and other website data are not shared
    ///     with the user's normal browser session and are discarded when the view
    ///     is dismissed. This forces the user to authenticate every time. Defaults to `false`.
    ///   - onCompletion: Called with the authorization response or error.
    public init(
        request: AuthorizationRequest,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @Sendable (Result<AuthorizationResponse, AuthError>) -> Void
    ) {
        self.request = request
        self.onCompletion = onCompletion

        if prefersEphemeralWebBrowserSession {
            var configuration = WebPage.Configuration()
            configuration.websiteDataStore = .nonPersistent()
            self._page = State(initialValue: WebPage(configuration: configuration))
        } else {
            self._page = State(initialValue: WebPage())
        }
    }

    public var body: some View {
        ZStack {
            WebView(page)
                .ignoresSafeArea(.container, edges: .bottom)
                .onChange(of: page.url) { _, newURL in
                    guard let newURL, !hasCompleted else { return }
                    checkForRedirect(url: newURL)
                }

            if page.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .task {
            let url = request.authorizationURL
            page.load(URLRequest(url: url))
        }
    }

    private func checkForRedirect(url: URL) {
        guard isRedirectURL(url) else { return }
        hasCompleted = true

        do {
            let response = try AuthorizationResponse.from(redirectURL: url, request: request)
            onCompletion(.success(response))
        } catch let error as AuthError {
            onCompletion(.failure(error))
        } catch {
            onCompletion(.failure(.unexpected(error.localizedDescription)))
        }
    }

    private func isRedirectURL(_ url: URL) -> Bool {
        let redirectScheme = request.redirectURL.scheme?.lowercased()
        let redirectHost = request.redirectURL.host?.lowercased()
        let redirectPath = request.redirectURL.path

        let urlScheme = url.scheme?.lowercased()
        let urlHost = url.host?.lowercased()
        let urlPath = url.path

        if urlScheme == redirectScheme && urlHost == redirectHost && urlPath == redirectPath {
            return true
        }

        // Also check if the URL starts with the redirect URI (for custom schemes)
        let redirectBase = request.redirectURL.absoluteString.split(separator: "?").first
            ?? Substring(request.redirectURL.absoluteString)
        let urlBase = url.absoluteString.split(separator: "?").first
            ?? Substring(url.absoluteString)

        return urlBase == redirectBase
    }
}

// MARK: - Full Authorization Flow View

/// A convenience SwiftUI view that handles the complete authorization code + token exchange flow.
///
/// Uses the iOS 26 / macOS 26 WebKit SwiftUI API for an in-app experience.
/// For iOS 17–25 / macOS 14–25, use ``AuthorizationBrowserFlowView`` instead.
///
/// Usage:
/// ```swift
/// AuthorizationFlowView(
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
@available(iOS 26.0, macOS 26.0, *)
public struct AuthorizationFlowView: View {
    private let syncRequest: AuthorizationRequest?
    private let requestProvider: (@Sendable () async throws -> AuthorizationRequest)?
    private let authState: AuthState
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @Sendable (Result<Void, AuthError>) -> Void

    @State private var resolvedRequest: AuthorizationRequest?
    @State private var isExchangingToken = false
    @State private var isLoadingRequest = false
    @State private var loadError: AuthError?

    /// Creates a full authorization flow view.
    /// - Parameters:
    ///   - request: The authorization request.
    ///   - authState: The auth state to update with tokens.
    ///   - prefersEphemeralWebBrowserSession: When `true`, uses a non-persistent
    ///     web data store so the user must authenticate every time. Defaults to `false`.
    ///   - onCompletion: Called when the flow completes or fails.
    public init(
        request: AuthorizationRequest,
        authState: AuthState,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @Sendable (Result<Void, AuthError>) -> Void
    ) {
        self.syncRequest = request
        self.requestProvider = nil
        self.authState = authState
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    /// Creates a full authorization flow view with an async request provider.
    ///
    /// Use this initializer when the authorization request needs to be built asynchronously
    /// (e.g., fetching OpenID Connect discovery metadata).
    /// - Parameters:
    ///   - request: An async throwing closure that produces the authorization request.
    ///   - authState: The auth state to update with tokens.
    ///   - prefersEphemeralWebBrowserSession: When `true`, uses a non-persistent
    ///     web data store so the user must authenticate every time. Defaults to `false`.
    ///   - onCompletion: Called when the flow completes or fails.
    public init(
        request: @escaping @Sendable () async throws -> AuthorizationRequest,
        authState: AuthState,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @Sendable (Result<Void, AuthError>) -> Void
    ) {
        self.syncRequest = nil
        self.requestProvider = request
        self.authState = authState
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    public var body: some View {
        ZStack {
            if let request = syncRequest ?? resolvedRequest {
                flowContent(request: request)
            }

            if isLoadingRequest {
                Color(.systemBackground)
                ProgressView("Preparing sign in…")
            }
        }
        .task {
            guard syncRequest == nil, requestProvider != nil else { return }
            isLoadingRequest = true
            do {
                resolvedRequest = try await requestProvider?()
            } catch let error as AuthError {
                authState.setError(error)
                onCompletion(.failure(error))
            } catch {
                let authError = AuthError.unexpected(error.localizedDescription)
                authState.setError(authError)
                onCompletion(.failure(authError))
            }
            isLoadingRequest = false
        }
    }

    @ViewBuilder
    private func flowContent(request: AuthorizationRequest) -> some View {
        ZStack {
            AuthorizationWebView(
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
                    Text("Completing sign in...")
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
            guard let code = authResponse.authorizationCode else {
                throw AuthError.unexpected("No authorization code")
            }
            let tokenRequest = TokenRequest.exchangeCode(from: authResponse)
            let tokenResponse = try await service.performTokenRequest(tokenRequest)
            _ = code // silence unused warning
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
#endif // os(iOS)
