import Foundation

/// An authorization session whose validity can be observed and refreshed over time.
///
/// Abstracts the parts of ``AuthState`` that ``SessionMonitor`` depends on, so the
/// monitor can be tested against a stub without a live token store.
@MainActor
public protocol AuthorizationSession: AnyObject {
    /// Whether a session currently exists (has an access token).
    var isAuthorized: Bool { get }

    /// The date at which the access token should be proactively refreshed, or `nil`
    /// when there is nothing to refresh.
    var nextRefreshDate: Date? { get }

    /// Refreshes the access token if it is expired or within the refresh window.
    /// Implementations should clear the session if a refresh fails.
    /// - Returns: `true` if a valid session exists afterwards; otherwise `false`.
    @discardableResult
    func ensureValidSession() async -> Bool
}

extension AuthState: AuthorizationSession {}

/// Keeps an ``AuthorizationSession`` fresh over time.
///
/// `SessionMonitor`'s single responsibility is time-driven session observation: it
/// schedules a proactive refresh just before the access token expires, re-validates
/// when asked (e.g. on app foreground), and publishes the outcome as an ``AsyncStream``
/// of ``Event`` values. It owns no presentation or navigation concerns — consumers
/// `for await` the events and translate them into UI.
@MainActor
public final class SessionMonitor {

    /// The outcome of a validation pass.
    public enum Event: Sendable {
        /// The session is valid (was already fresh or was successfully refreshed).
        case refreshed
        /// The session ended and could not be refreshed; the user should sign in again.
        case expired
    }

    /// A stream of validation outcomes. Iterate with `for await` to react to session
    /// changes. The stream finishes when the monitor is deinitialized.
    public let events: AsyncStream<Event>

    private let session: AuthorizationSession
    private let continuation: AsyncStream<Event>.Continuation
    private var timerTask: Task<Void, Never>?

    /// Creates a monitor for the given session.
    /// - Parameter session: The session to keep fresh.
    public init(session: AuthorizationSession) {
        self.session = session
        (events, continuation) = AsyncStream.makeStream()
    }

    deinit {
        timerTask?.cancel()
        continuation.finish()
    }

    /// Begins monitoring, scheduling the next proactive refresh if a session exists.
    public func start() {
        scheduleRefresh()
    }

    /// Re-validates the session immediately, refreshing if needed. Use this when the app
    /// returns to the foreground, where a scheduled refresh may have been suspended.
    public func revalidate() async {
        await validate()
    }

    /// Stops monitoring and cancels any pending refresh.
    public func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Private

    private func validate() async {
        guard session.isAuthorized else {
            stop()
            return
        }

        if await session.ensureValidSession() {
            scheduleRefresh()
            continuation.yield(.refreshed)
        } else {
            stop()
            continuation.yield(.expired)
        }
    }

    private func scheduleRefresh() {
        stop()

        guard let refreshDate = session.nextRefreshDate else { return }
        let interval = refreshDate.timeIntervalSinceNow

        timerTask = Task { [weak self] in
            if interval > 0 {
                try? await Task.sleep(for: .seconds(interval))
            }
            guard !Task.isCancelled else { return }
            await self?.validate()
        }
    }
}
