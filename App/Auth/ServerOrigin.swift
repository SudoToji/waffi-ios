import Foundation

/// The Waffi server the app talks to: production, unless a tester typed another https address on the sign-in screen.
/// The override exists only in Debug and TestFlight builds, so an App Store build can never be pointed elsewhere.
enum ServerOrigin {
    static let production = URL(string: "https://waffieg.com")!
    private static let key = "serverOrigin"

    /// True in Debug and TestFlight builds (their receipt is `sandboxReceipt`), false in the App Store.
    static var canChange: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static var current: URL {
        guard canChange, let saved = UserDefaults.standard.string(forKey: key), let url = parse(saved) else { return production }
        return url
    }

    /// What the Server field shows: empty while production is used.
    static var saved: String {
        canChange ? UserDefaults.standard.string(forKey: key) ?? "" : ""
    }

    /// Remembers `text` (empty = back to production). False when it is not an https address.
    @discardableResult
    static func save(_ text: String) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canChange else { return false }
        if text.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
            return true
        }
        guard let url = parse(text) else { return false }
        UserDefaults.standard.set(url.absoluteString, forKey: key)
        return true
    }

    /// `https://host[:port]` only: any path, query or fragment is dropped. Nil for anything else.
    static func parse(_ text: String) -> URL? {
        guard let parts = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil
        else { return nil }
        var origin = URLComponents()
        origin.scheme = "https"
        origin.host = host
        origin.port = parts.port
        return origin.url
    }

    /// The website's language prefix for this phone.
    static var language: String {
        Locale.preferredLanguages.first?.hasPrefix("ar") == true ? "ar" : "en"
    }
}
