import Foundation

/// An API refusal. `code` is the UPPER_SNAKE code the API sends (`ERROR_CODES` in waffi `packages/shared`), or one the app makes
/// up for a failure that has none: `NETWORK` when the server cannot be reached.
struct ApiError: Error, Equatable {
    let code: String
    var status = 0

    static let network = ApiError(code: "NETWORK")

    init(code: String, status: Int = 0) {
        self.code = code
        self.status = status
    }

    /// The code in the body, or one for the HTTP status when the body has none.
    init(status: Int, body: Data) {
        self.status = status
        if let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let message = object["message"] as? String,
           message.range(of: "^[A-Z][A-Z0-9_]+$", options: .regularExpression) != nil {
            code = message
            return
        }
        switch status {
        case 401: code = "UNAUTHENTICATED"
        case 403: code = "FORBIDDEN"
        case 429: code = "RATE_LIMIT"
        case 400: code = "VALIDATION"
        case 500...: code = "NETWORK"
        default: code = "GENERIC"
        }
    }

    /// The refusal in the phone's language (`error.<CODE>` in the String Catalog); an unknown code reads as `GENERIC`.
    var message: String {
        let key = "error.\(code)"
        let text = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        return text == key ? Bundle.main.localizedString(forKey: "error.GENERIC", value: nil, table: nil) : text
    }

    /// The server could not be reached or is having trouble: worth trying again, nothing is wrong with the account.
    var isTemporary: Bool { status == 0 || status == 429 || status >= 500 }
}
