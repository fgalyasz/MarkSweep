import Foundation
import Security

public let markSweepKeychainService = "com.tenprintsoftware.MarkSweep"
public let markSweepKeychainAccount = "gmail-oauth"

public func keychainBaseQuery(
    service: String = markSweepKeychainService,
    account: String = markSweepKeychainAccount
) -> [String: Any] {
    [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecUseDataProtectionKeychain as String: true
    ]
}

public func keychainLoadQuery(
    service: String = markSweepKeychainService,
    account: String = markSweepKeychainAccount
) -> [String: Any] {
    var query = keychainBaseQuery(service: service, account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    return query
}

public func keychainAddQuery(
    data: Data,
    service: String = markSweepKeychainService,
    account: String = markSweepKeychainAccount
) -> [String: Any] {
    var query = keychainBaseQuery(service: service, account: account)
    query[kSecValueData as String] = data
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    return query
}

public func keychainUsesDataProtection(_ query: [String: Any]) -> Bool {
    query[kSecUseDataProtectionKeychain as String] as? Bool == true
}
