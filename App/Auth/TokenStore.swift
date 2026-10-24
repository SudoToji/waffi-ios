import Foundation
import Security

struct StoredTokens: Codable, Equatable {
    var access: String
    var refresh: String
}

/// The session tokens, kept only in the Keychain: this device only, readable after the first unlock, never synced.
enum TokenStore {
    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.waffieg.app.session",
        kSecAttrAccount as String: "tokens",
    ]

    static func load() -> StoredTokens? {
        // A Keychain item outlives the app: after a reinstall the first launch starts signed out.
        let ranBefore = "ranBefore"
        if !UserDefaults.standard.bool(forKey: ranBefore) {
            UserDefaults.standard.set(true, forKey: ranBefore)
            delete()
            return nil
        }
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }

    static func save(_ tokens: StoredTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        delete()
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static func delete() {
        SecItemDelete(query as CFDictionary)
    }
}
