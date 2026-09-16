import Foundation
import Security
import MarkSweepCore

struct KeychainTokenStore: TokenStoring {
    let service = markSweepKeychainService
    let account = markSweepKeychainAccount

    func load() throws -> OAuthToken? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainLoadQuery() as CFDictionary, &item)
        return try tokenFromKeychain(status: status, item: item)
    }

    func save(_ token: OAuthToken) throws {
        try clear()
        let data = try JSONEncoder().encode(token)
        let status = SecItemAdd(keychainAddQuery(data: data) as CFDictionary, nil)
        if status != errSecSuccess { throw MarkSweepError.decode }
    }

    func clear() throws {
        SecItemDelete(keychainBaseQuery() as CFDictionary)
    }
}

func tokenFromKeychain(status: OSStatus, item: CFTypeRef?) throws -> OAuthToken? {
    if status == errSecItemNotFound { return nil }
    if status != errSecSuccess { throw MarkSweepError.decode }
    guard let data = item as? Data else { return nil }
    return try JSONDecoder().decode(OAuthToken.self, from: data)
}
