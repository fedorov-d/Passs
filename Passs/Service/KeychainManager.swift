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
    case userCancelled
    case itemNotFound
}

protocol KeychainManager: AnyObject {
    func setItem(_: String, for key: String) throws
    func item(for key: String) throws -> String?
    func deleteItem(for key: String) throws
}

final class KeychainManagerImp: KeychainManager {

    func setItem(_ item: String, for key: String) throws {

        var query: [AnyHashable: Any] = [kSecClass: kSecClassInternetPassword,
                                        kSecAttrServer: "",
                                        kSecAttrAccount: key]
        let status: OSStatus
        if let _ = try? self.item(for: query) {
            let updateQuery = [kSecValueData: item.data(using: .utf8)]
            status = SecItemUpdate(updateQuery as CFDictionary, query as CFDictionary)
        } else {
            query[kSecValueData] = item.data(using: .utf8)
            status = SecItemAdd(query as CFDictionary, nil)

        }
        guard status == errSecSuccess else {
            throw KeychainError.cantSavePassword
        }
    }

    func item(for key: String) throws -> String? {
        let query = query(for: key)
        return try self.item(for: query)
    }

    func deleteItem(for key: String) throws {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: key
        ] as [String: Any]
        let _ = SecItemDelete(query as CFDictionary)
    }

    private func item(for query: [AnyHashable: Any]) throws -> String? {
        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
        switch status {
        case errSecUserCanceled:
            throw KeychainError.userCancelled
        case errSecSuccess:
            guard let data = itemCopy as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }

    private func query(for key: String) -> [AnyHashable: Any] {
        [kSecClass: kSecClassInternetPassword,
        kSecAttrServer: "",
        kSecAttrAccount: key,
        kSecMatchLimit: kSecMatchLimitOne,
        kSecReturnData: true]
    }

}
