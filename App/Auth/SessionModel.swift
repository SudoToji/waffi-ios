import Observation

/// Who is signed in. The screens change with `state`; the API client reports every answer that ends the session.
@Observable @MainActor
final class SessionModel {
    enum State: Equatable {
        case starting
        /// The server could not be reached while checking the saved session: the tokens are kept, so Retry may work.
        case unreachable(ApiError)
        case signedOut
        /// A Temporary Password: nothing else works until it is replaced.
        case mustChangePassword(AppAccount)
        case signedIn(AppAccount)
    }

    private(set) var state = State.starting
    /// Why the API ended the session (its message in the phone's language), shown on the sign-in screen.
    private(set) var notice: String?

    @ObservationIgnored private(set) lazy var api = ApiClient { [weak self] code in
        Task { @MainActor in self?.sessionIssue(code) }
    }

    /// Checks the saved session when the app opens.
    func start() async {
        state = .starting
        guard await api.hasTokens else {
            state = .signedOut
            return
        }
        do {
            enter(try await api.get("api/auth/me"))
        } catch let error as ApiError where error.isTemporary {
            state = .unreachable(error)
        } catch {
            // The session ended: `sessionIssue` has already moved to the right screen.
        }
    }

    func signIn(email: String, password: String) async throws {
        enter(try await api.signIn(email: email, password: password))
    }

    func changePassword(current: String, new: String) async throws {
        enter(try await api.changePassword(current: current, new: new))
    }

    func signOut() async {
        await api.signOut()
        notice = nil
        state = .signedOut
    }

    private func enter(_ account: AppAccount) {
        notice = nil
        state = account.user.mustChangePassword ? .mustChangePassword(account) : .signedIn(account)
    }

    private func sessionIssue(_ code: String) {
        if code == "PASSWORD_CHANGE_REQUIRED" {
            if case .signedIn(let account) = state { state = .mustChangePassword(account) }
            return
        }
        notice = ApiError(code: code).message
        state = .signedOut
    }
}
