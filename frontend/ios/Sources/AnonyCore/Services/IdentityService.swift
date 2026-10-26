import Foundation
import Security

public final class IdentityService: Sendable {
    public static let shared = IdentityService()

    private let serviceIdentifier = "com.anony.mobile"
    private let tokenServiceKey = "com.anony.mobile.sessionToken"
    private let aliasServiceKey = "com.anony.mobile.userAlias"
    private let emailServiceKey = "com.anony.mobile.userEmail"

    public init() {}

    // MARK: - Generic Keychain Helpers

    private func saveKeychainItem(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func fetchKeychainItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychainItem(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Token Management

    public func saveToken(_ token: String) -> Bool {
        return saveKeychainItem(key: tokenServiceKey, value: token)
    }

    public func fetchToken() -> String? {
        return fetchKeychainItem(key: tokenServiceKey)
    }

    // MARK: - Alias Management

    public func saveAlias(_ alias: String) -> Bool {
        return saveKeychainItem(key: aliasServiceKey, value: alias)
    }

    public func fetchAlias() -> String? {
        return fetchKeychainItem(key: aliasServiceKey)
    }

    // MARK: - Email Management

    public func saveEmail(_ email: String) -> Bool {
        return saveKeychainItem(key: emailServiceKey, value: email)
    }

    public func fetchEmail() -> String? {
        return fetchKeychainItem(key: emailServiceKey)
    }

    // MARK: - Session Operations

    public func saveSession(token: String, alias: String, email: String) -> Bool {
        let savedToken = saveToken(token)
        let savedAlias = saveAlias(alias)
        let savedEmail = saveEmail(email)
        return savedToken && savedAlias && savedEmail
    }

    public func hasActiveSession() -> Bool {
        guard let token = fetchToken() else { return false }
        return !token.isEmpty
    }

    public func clearSession() -> Bool {
        let deletedToken = deleteKeychainItem(key: tokenServiceKey)
        let deletedAlias = deleteKeychainItem(key: aliasServiceKey)
        let deletedEmail = deleteKeychainItem(key: emailServiceKey)
        return deletedToken && deletedAlias && deletedEmail
    }
}
