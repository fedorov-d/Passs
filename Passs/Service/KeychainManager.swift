//
//  KeychainManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 17.01.2022.
//

import Foundation
import Security

enum KeychainError: Error {
    case cantSavePassword
}

protocol KeychainManager: AnyObject {
    func savePassword(_: String, for database: String) throws
    func savedPassword(for database: String) -> String?
}

class KeychainManagerImp: KeychainManager {

    let userDefaults = UserDefaults.standard

    func savePassword(_ password: String, for database: String) throws {
        userDefaults.set(true, forKey: database)
        userDefaults.synchronize()

        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            nil
        )
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: database,
            kSecAttrServer as String: "",
            kSecAttrAccessControl as String: access as Any,
            kSecValueData as String: password.data(using: .utf8) as Any
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.cantSavePassword }
    }

    func hasSavedPassword(for database: String) -> Bool {
        userDefaults.bool(forKey: database) == true
    }

    func savedPassword(for database: String) -> String? {
        guard hasSavedPassword(for: database) else { return nil }

        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: database,
                                    kSecAttrServer as String: "",
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecUseOperationPrompt as String: "Access your password on the keychain",
                                    kSecReturnData as String: true]
        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
        guard status == errSecSuccess,
              let data = itemCopy as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

}
