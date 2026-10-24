import Foundation

/// A Pager Ticket as `GET /api/pager/public/ticket` answers it (`PublicPagerTicket` in waffi `packages/shared/src/contracts/pager.ts`).
/// An ended, unknown or malformed ticket is the bare `{ "state": "ended" }`, so the other fields are read only for an open one.
struct PagerTicket: Decodable, Equatable {
    var state: PagerState
    var businessName = ""
    /// A path on the API (`/api/assets/logos/...`), or nil.
    var logoUrl: String?
    var branchName = ""
    var number = ""

    private enum CodingKeys: String, CodingKey { case state, businessName, logoUrl, branchName, number }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decode(PagerState.self, forKey: .state)
        guard state != .ended else { return }
        businessName = try c.decode(String.self, forKey: .businessName)
        logoUrl = try c.decodeIfPresent(String.self, forKey: .logoUrl)
        branchName = try c.decode(String.self, forKey: .branchName)
        number = try c.decode(String.self, forKey: .number)
    }
}

enum PagerClientError: Error {
    case status(Int)
}

/// Which app follows a ticket: the API wants to know whether to address a push to the full app or to its App Clip.
enum PagerHost: String {
    case app, clip
}

/// The Pager's public API for one ticket. The token is the only credential and travels in `X-Pager-Token`, never in a URL.
/// Shared by the App Clip and the full app.
struct PagerClient {
    /// `https://<host>[:port]` of the invocation URL: the API is the site that printed the QR (production, or a tunnel while testing).
    let origin: URL
    let token: String

    /// Matches `PAGER_TOKEN_PATTERN`: 32 random bytes in base64url.
    private static let tokenPattern = "^[A-Za-z0-9_-]{43}$"

    /// Nil unless `url` is `https://<host>/p/<token>`.
    init?(invocation url: URL) {
        let parts = url.pathComponents
        guard url.scheme == "https", let host = url.host,
              parts.count == 3, parts[1] == "p",
              parts[2].range(of: Self.tokenPattern, options: .regularExpression) != nil
        else { return nil }
        var origin = URLComponents()
        origin.scheme = "https"
        origin.host = host
        origin.port = url.port
        guard let origin = origin.url else { return nil }
        self.origin = origin
        self.token = parts[2]
    }

    func ticket() async throws -> PagerTicket {
        let data = try await send(request(path: "api/pager/public/ticket"))
        return try JSONDecoder().decode(PagerTicket.self, from: data)
    }

    /// The Business logo, or nil. Only a path under `/api/assets/logos/` on the API is fetched.
    func logo(at path: String) async -> Data? {
        guard path.hasPrefix("/api/assets/logos/") else { return nil }
        var request = request(path: path)
        request.timeoutInterval = 5
        return try? await send(request)
    }

    /// Registers a Live Activity push token on the ticket.
    func registerLiveActivity(token pushToken: Data, host: PagerHost) async throws {
        struct Target: Encodable { let token: String; let app: String }
        struct Body: Encodable { let kind = "live_activity"; let target: String; let locale: String }
        // The API wants `target` as JSON text inside the JSON body.
        let target = try JSONEncoder().encode(Target(token: pushToken.map { String(format: "%02x", $0) }.joined(), app: host.rawValue))
        var request = request(path: "api/pager/public/devices")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(target: String(decoding: target, as: UTF8.self), locale: Self.locale))
        _ = try await send(request)
    }

    /// The phone's language as the API knows it.
    private static var locale: String {
        Locale.preferredLanguages.first?.hasPrefix("ar") == true ? "ar" : "en"
    }

    private func request(path: String) -> URLRequest {
        var request = URLRequest(url: origin.appending(path: path))
        request.setValue(token, forHTTPHeaderField: "X-Pager-Token")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            throw PagerClientError.status(status)
        }
        return data
    }
}
