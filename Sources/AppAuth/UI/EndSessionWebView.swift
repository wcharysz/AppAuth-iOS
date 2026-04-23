import SwiftUI
import WebKit

/// A SwiftUI view that presents the OpenID Connect end session (logout) flow in an in-app WebView.
///
/// Uses the iOS 26 WebKit SwiftUI API (`WebView` + `WebPage`) to display
/// the provider's logout page and intercept the post-logout redirect.
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
public struct EndSessionWebView: View {
    private let request: EndSessionRequest
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    @State private var page = WebPage()
    @State private var hasCompleted = false

    public init(
        request: EndSessionRequest,
        onCompletion: @escaping @MainActor (Result<Void, AuthError>) -> Void
    ) {
        self.request = request
        self.onCompletion = onCompletion
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
public struct LogoutFlowView: View {
    private let request: EndSessionRequest
    private let authState: AuthState
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    public init(
        request: EndSessionRequest,
        authState: AuthState,
        onCompletion: @escaping @MainActor (Result<Void, AuthError>) -> Void
    ) {
        self.request = request
        self.authState = authState
        self.onCompletion = onCompletion
    }

    public var body: some View {
        EndSessionWebView(request: request) { result in
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
