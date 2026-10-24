import Foundation

/// The staff app's way to the API (`docs/adr/0006-app-sign-in-bearer-tokens.md` in waffi): `Authorization: Bearer` on every call, no cookies.
/// An `UNAUTHENTICATED` answer is followed by one refresh and one retry; a refresh the server refuses ends the session.
actor ApiClient {
    /// Answers that end the session. `PASSWORD_CHANGE_REQUIRED` keeps the tokens: only the password can change now.
    private static let endsSession: Set<String> = [
        "UNAUTHENTICATED", "AWAITING_APPROVAL", "SUBSCRIPTION_ENDED", "TEAM_SEAT_LOCKED", "PASSWORD_CHANGE_REQUIRED",
    ]

    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }()

    private let onSessionIssue: @Sendable (String) -> Void
    private var tokens = TokenStore.load()
    private var refreshing: Task<Void, Error>?

    /// `onSessionIssue` hears the code of every answer in `endsSession`, after the tokens are dealt with.
    init(onSessionIssue: @escaping @Sendable (String) -> Void) {
        self.onSessionIssue = onSessionIssue
    }

    var hasTokens: Bool { tokens != nil }

    // MARK: Calls

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try decode(await authorized(path, query: query, method: "GET", body: nil))
    }

    func post<T: Decodable>(_ path: String, json: (any Encodable)? = nil) async throws -> T {
        try decode(await authorized(path, query: [], method: "POST", body: json))
    }

    func put<T: Decodable>(_ path: String, json: (any Encodable)? = nil) async throws -> T {
        try decode(await authorized(path, query: [], method: "PUT", body: json))
    }

    func delete<T: Decodable>(_ path: String, json: (any Encodable)? = nil) async throws -> T {
        try decode(await authorized(path, query: [], method: "DELETE", body: json))
    }

    func signIn(email: String, password: String) async throws -> AppAccount {
        let answer: AppSignIn = try decode(
            await send("api/auth/app/login", method: "POST", body: ["email": email, "password": password]))
        store(answer)
        return answer.session
    }

    func changePassword(current: String, new: String) async throws -> AppAccount {
        let answer: AppSignIn = try decode(
            await authorized(
                "api/auth/app/change-password", query: [], method: "POST",
                body: ["currentPassword": current, "newPassword": new]))
        store(answer)
        return answer.session
    }

    /// Ends this device's session on the server (if it can be reached) and forgets the tokens.
    func signOut() async {
        if let access = tokens?.access {
            _ = try? await send("api/auth/app/logout", method: "POST", bearer: access)
        }
        forget()
    }

    // MARK: Plumbing

    private func store(_ answer: AppSignIn) {
        let tokens = StoredTokens(access: answer.accessToken, refresh: answer.refreshToken)
        self.tokens = tokens
        TokenStore.save(tokens)
    }

    private func forget() {
        tokens = nil
        TokenStore.delete()
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = try? Date(text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) { return date }
            return try Date(text, strategy: Date.ISO8601FormatStyle())
        }
        do { return try decoder.decode(T.self, from: data) } catch { throw ApiError(code: "INVALID_RESPONSE") }
    }

    private func authorized(_ path: String, query: [URLQueryItem], method: String, body: (any Encodable)?) async throws -> Data {
        do {
            guard let used = tokens?.access else { throw ApiError(code: "UNAUTHENTICATED") }
            do {
                return try await send(path, query: query, method: method, body: body, bearer: used)
            } catch let error as ApiError where error.code == "UNAUTHENTICATED" {
                try await refresh(after: used)
                guard let fresh = tokens?.access else { throw error }
                return try await send(path, query: query, method: method, body: body, bearer: fresh)
            }
        } catch let error as ApiError where Self.endsSession.contains(error.code) {
            if error.code != "PASSWORD_CHANGE_REQUIRED" {
                if error.code != "UNAUTHENTICATED", let access = tokens?.access {
                    Task { _ = try? await send("api/auth/app/logout", method: "POST", bearer: access) }
                }
                forget()
            }
            onSessionIssue(error.code)
            throw error
        }
    }

    /// One refresh at a time: calls that fail together wait for the same one, and a call that finds newer tokens just retries.
    private func refresh(after failed: String) async throws {
        if tokens?.access != failed { return }
        if let refreshing { return try await refreshing.value }
        let task = Task { try await performRefresh() }
        refreshing = task
        defer { refreshing = nil }
        try await task.value
    }

    private func performRefresh() async throws {
        guard let refreshToken = tokens?.refresh else { throw ApiError(code: "UNAUTHENTICATED") }
        do {
            let answer: AppSignIn = try decode(
                await send("api/auth/app/refresh", method: "POST", body: ["refreshToken": refreshToken]))
            store(answer)
        } catch let error as ApiError where !error.isTemporary {
            throw Self.endsSession.contains(error.code) ? error : ApiError(code: "UNAUTHENTICATED", status: error.status)
        }
    }

    private func send(
        _ path: String, query: [URLQueryItem] = [], method: String, body: (any Encodable)? = nil, bearer: String? = nil
    ) async throws -> Data {
        var components = URLComponents(url: ServerOrigin.current, resolvingAgainstBaseURL: false)!
        components.path = "/" + path
        components.queryItems = query.isEmpty ? nil : query
        // A `+` (a phone number) stays a plus: the server reads an unescaped one as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer { request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw ApiError.network
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw ApiError(status: status, body: data) }
        return data
    }
}
