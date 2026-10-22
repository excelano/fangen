// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Security

/// Player private keys, one per game. This-device-only and never synchronized, so they stay out of
/// iCloud Keychain and out of backups.
enum Keychain {
    struct Failure: Error {
        let status: OSStatus
    }

    private static let service = "com.excelano.fangen.player-key"

    private static func query(gameID: Data) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: gameID.base64EncodedString(),
        ]
    }

    static func savePlayerKey(_ key: Data, gameID: Data) throws {
        SecItemDelete(query(gameID: gameID) as CFDictionary)
        var item = query(gameID: gameID)
        item[kSecValueData as String] = key
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        item[kSecAttrSynchronizable as String] = false
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure(status: status) }
    }
}
