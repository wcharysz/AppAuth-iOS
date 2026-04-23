// WebKit SwiftUI views (WebView, WebPage) require iOS 26+.
// Guarded with #if os(iOS) to work around a macOS SDK swiftinterface bug
// where AsyncSequence<Element, Failure> typed throws lack proper availability annotations.
// On macOS, use EndSessionBrowserView / LogoutBrowserFlowView instead.
#if os(iOS)
import SwiftUI
import WebKit

/// A SwiftUI view that presents the OpenID Connect end session (logout) flow in an in-app WebView.
///
/// Uses the iOS 26 / macOS 26 WebKit SwiftUI API (`WebView` + `WebPage`) to display
/// the provider's logout page and intercept the post-logout redirect.
///
/// For iOS 17–25 / macOS 14–25, use ``EndSessionBrowserView`` instead, which uses
/// `ASWebAuthenticationSession` to present the logout flow in a system browser.
///
/// Usage:
/// ```swift
/// EndSessionWebView(request: endSessionRequest) { result in
///     switch result {
///     case .success:
///         // Logout completed
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
public struct EndSessionWebView: View {
    private let request: EndSessionRequest
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    @State private var page: WebPage
    @State private var hasCompleted = false

    /// Creates an end session web view.
    /// - Parameters:
    ///   - request: The end session request to present.
    ///   - prefersEphemeralWebBrowserSession: When `true`, uses a non-persistent
    ///     `WKWebsiteDataStore` so cookies and website data are discarded.
    ///     Defaults to `false`.
    ///   - onCompletion: Called when the logout completes or fails.
    public init(
        request: EndSessionRequest,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @MainActor (Result<Void, AuthError>) -> Void
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
                    checkForPostLogoutRedirect(url: newURL)
                }

            if page.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .task {
            do {
                let url = try request.endSessionURL
                page.load(URLRequest(url: url))
            } catch let error as AuthError {
                onCompletion(.failure(error))
            } catch {
                onCompletion(.failure(.unexpected(error.localizedDescription)))
            }
        }
    }

    private func checkForPostLogoutRedirect(url: URL) {
        guard let redirectURL = request.postLogoutRedirectURL else {
            // No post-logout redirect — consider any navigation after the initial load as complete
            return
        }

        guard isPostLogoutRedirectURL(url, redirectURL: redirectURL) else { return }
        hasCompleted = true

        // Validate state if present
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
           let returnedState = stateItem.value,
           returnedState != request.state
        {
            onCompletion(.failure(.stateMismatch))
            return
        }

        onCompletion(.success(()))
    }

    private func isPostLogoutRedirectURL(_ url: URL, redirectURL: URL) -> Bool {
        let redirectBase = redirectURL.absoluteString.split(separator: "?").first
            ?? Substring(redirectURL.absoluteString)
        let urlBase = url.absoluteString.split(separator: "?").first
            ?? Substring(url.absoluteString)

        return urlBase == redirectBase
    }
}

// MARK: - Full Logout Flow View

/// A convenience SwiftUI view that handles the complete end session flow and clears auth state.
///
/// Uses the iOS 26 / macOS 26 WebKit SwiftUI API for an in-app experience.
/// For iOS 17–25 / macOS 14–25, use ``LogoutBrowserFlowView`` instead.
///
/// Usage:
/// ```swift
/// LogoutFlowView(
///     request: endSessionRequest,
///     authState: authState
/// ) { result in
///     switch result {
///     case .success:
///         // User is logged out, state is cleared
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
public struct LogoutFlowView: View {
    private let request: EndSessionRequest
    private let authState: AuthState
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    /// Creates a full logout flow view.
    /// - Parameters:
    ///   - request: The end session request.
    ///   - authState: The auth state to clear on success.
    ///   - prefersEphemeralWebBrowserSession: When `true`, uses a non-persistent
    ///     web data store. Defaults to `false`.
    ///   - onCompletion: Called when the flow completes or fails.
    public init(
        request: EndSessionRequest,
        authState: AuthState,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @MainActor (Result<Void, AuthError>) -> Void
    ) {
        self.request = request
        self.authState = authState
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    public var body: some View {
        EndSessionWebView(
            request: request,
            prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession
        ) { result in
            switch result {
            case .success:
                authState.clear()
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}
#endif // os(iOS)
