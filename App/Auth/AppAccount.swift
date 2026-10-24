import Foundation

/// The session as `POST /api/auth/app/login` and `GET /api/auth/me` answer it (`Session` in waffi `packages/shared`), reduced to what the app uses.
struct AppAccount: Decodable, Equatable {
    struct User: Decodable, Equatable {
        let id: String
        let email: String
        let fullName: String?
        /// `owner`, `manager` or `cashier` (a Staff Member).
        let role: String
        let mustChangePassword: Bool
        /// A Staff Member's permissions (`STAFF_PERMISSIONS`); absent for the others.
        let permissions: [String]?
    }

    struct Business: Decodable, Equatable {
        let id: String
        let name: String
    }

    let user: User
    let business: Business
}

extension AppAccount.User {
    /// What a Staff Member may do when the Owner never changed it (`DEFAULT_STAFF_PERMISSIONS`).
    private static let defaultPermissions = ["loyalty.earn", "loyalty.redeem"]

    /// `hasStaffPermission`: an Owner or Manager may do everything, a Staff Member what their permissions list.
    func may(_ permission: String) -> Bool {
        role == "owner" || role == "manager" || (permissions ?? Self.defaultPermissions).contains(permission)
    }
}

/// The token pair that `/api/auth/app/login`, `refresh` and `change-password` answer with (`AppSignIn`).
struct AppSignIn: Decodable {
    let accessToken: String
    let refreshToken: String
    let session: AppAccount
}
