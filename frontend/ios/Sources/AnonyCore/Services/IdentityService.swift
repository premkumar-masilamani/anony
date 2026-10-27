import Foundation
import Security

public final class IdentityService: Sendable {
    public static let shared = IdentityService()

    private let serviceIdentifier: String
    private let tokenServiceKey: String
    private let aliasServiceKey: String
    private let emailServiceKey: String
    private let roleServiceKey: String

    public init(serviceIdentifier: String = "com.anony.mobile") {
        self.serviceIdentifier = serviceIdentifier
        self.tokenServiceKey = "\(serviceIdentifier).sessionToken"
        self.aliasServiceKey = "\(serviceIdentifier).userAlias"
        self.emailServiceKey = "\(serviceIdentifier).userEmail"
        self.roleServiceKey = "\(serviceIdentifier).userRole"
    }

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

    // MARK: - Role Management

    public func saveRole(_ role: String) -> Bool {
        return saveKeychainItem(key: roleServiceKey, value: role)
    }

    public func fetchRole() -> String? {
        return fetchKeychainItem(key: roleServiceKey)
    }

    // MARK: - Session Operations

    public func saveSession(token: String, alias: String, email: String, role: String = "CLIENT") -> Bool {
        let savedToken = saveToken(token)
        let savedAlias = saveAlias(alias)
        let savedEmail = saveEmail(email)
        let savedRole = saveRole(role)
        return savedToken && savedAlias && savedEmail && savedRole
    }

    public func hasActiveSession() -> Bool {
        guard let token = fetchToken() else { return false }
        return !token.isEmpty
    }

    public func clearSession() -> Bool {
        let deletedToken = deleteKeychainItem(key: tokenServiceKey)
        let deletedAlias = deleteKeychainItem(key: aliasServiceKey)
        let deletedEmail = deleteKeychainItem(key: emailServiceKey)
        let deletedRole = deleteKeychainItem(key: roleServiceKey)
        return deletedToken && deletedAlias && deletedEmail && deletedRole
    }
}
