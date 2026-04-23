import SwiftUI
import AuthenticationServices

/// A SwiftUI view that presents the OpenID Connect end session (logout) flow using the system browser
/// via `ASWebAuthenticationSession`.
///
/// Requires a `postLogoutRedirectURL` with a custom URL scheme so the system browser can
/// detect when the provider completes the logout flow.
///
/// Available on iOS 17+ and macOS 14+ (Sonoma). On iOS 26+ / macOS 26+, consider using
/// ``EndSessionWebView`` for an in-app WebView experience.
///
/// Usage:
/// ```swift
/// EndSessionBrowserView(request: endSessionRequest) { result in
///     switch result {
///     case .success:
///         // Logout completed
///     case .failure(let error):
///         // Handle error
///     }
/// }
/// ```
public struct EndSessionBrowserView: View {
    private let request: EndSessionRequest
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    @State private var hasStarted = false

    /// Creates an end session browser view.
    /// - Parameters:
    ///   - request: The end session request to present. Must have a `postLogoutRedirectURL`
    ///     with a custom URL scheme.
    ///   - prefersEphemeralWebBrowserSession: When `true`, the browser session does not share
    ///     cookies or data with the user's normal browser session. Defaults to `false`.
    ///   - onCompletion: Called when the logout completes or fails.
    public init(
        request: EndSessionRequest,
        prefersEphemeralWebBrowserSession: Bool = false,
        onCompletion: @escaping @MainActor (Result<Void, AuthError>) -> Void
    ) {
        self.request = request
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        self.onCompletion = onCompletion
    }

    public var body: some View {
        ProgressView("Signing out…")
            .task {
                guard !hasStarted else { return }
                hasStarted = true
                await startSession()
            }
    }

    @MainActor
    private func startSession() async {
        guard let postLogoutRedirectURL = request.postLogoutRedirectURL else {
            onCompletion(.failure(.unexpected(
                "postLogoutRedirectURL is required for browser-based end session flows"
            )))
            return
        }

        do {
            let endSessionURL = try request.endSessionURL
            let callbackScheme = postLogoutRedirectURL.scheme

            let callbackURL = try await performLogout(
                url: endSessionURL,
                callbackScheme: callbackScheme
            )

            // Validate state if present
            if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
               let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
               let returnedState = stateItem.value,
               returnedState != request.state
            {
                onCompletion(.failure(.stateMismatch))
                return
            }

            onCompletion(.success(()))
        } catch let error as AuthError {
            onCompletion(.failure(error))
        } catch {
            onCompletion(.failure(.unexpected(error.localizedDescription)))
        }
    }

    @MainActor
    private func performLogout(url: URL, callbackScheme: String?) async throws -> URL {
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

// MARK: - Full Logout Flow View (Browser)

/// A convenience SwiftUI view that handles the complete end session flow and clears auth state
/// using the system browser via `ASWebAuthenticationSession`.
///
/// Available on iOS 17+ and macOS 14+. On iOS 26+ / macOS 26+, consider using
/// ``LogoutFlowView`` for an in-app WebView experience.
///
/// Usage:
/// ```swift
/// LogoutBrowserFlowView(
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
public struct LogoutBrowserFlowView: View {
    private let request: EndSessionRequest
    private let authState: AuthState
    private let prefersEphemeralWebBrowserSession: Bool
    private let onCompletion: @MainActor (Result<Void, AuthError>) -> Void

    /// Creates a full logout flow browser view.
    /// - Parameters:
    ///   - request: The end session request.
    ///   - authState: The auth state to clear on success.
    ///   - prefersEphemeralWebBrowserSession: When `true`, the browser session does not share
    ///     cookies or data with the user's normal browser session. Defaults to `false`.
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
        EndSessionBrowserView(
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
