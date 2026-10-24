import Foundation

/// The session as `POST /api/auth/app/login` and `GET /api/auth/me` answer it (`Session` in waffi `packages/shared`), reduced to what the app uses.
struct AppAccount: Decodable, Equatable {
    struct User: Decodable, Equatable {
        let id: String
        let email: String
        let mustChangePassword: Bool
    }

    struct Business: Decodable, Equatable {
        let id: String
        let name: String
    }

    let user: User
    let business: Business
}

/// The token pair that `/api/auth/app/login`, `refresh` and `change-password` answer with (`AppSignIn`).
struct AppSignIn: Decodable {
    let accessToken: String
    let refreshToken: String
    let session: AppAccount
}
