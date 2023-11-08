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

let applicationGroupIdentifier = "3YK694S6H3.com.sw1.dftest.shared"

final class KeychainManagerImp: KeychainManager {
    func setItem(_ item: String, for key: String) throws {
        var query: [AnyHashable: Any] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "",
            kSecAttrAccessGroup: applicationGroupIdentifier,
            kSecAttrAccount: key
        ]
        let status: OSStatus
        if let _ = try? self.item(for: key) {
            let updateQuery = [kSecValueData: item.data(using: .utf8)]
            status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
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
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "",
            kSecAttrAccessGroup: applicationGroupIdentifier,
            kSecAttrAccount: key
        ] as [String: Any]
        let status = SecItemDelete(query as CFDictionary)
        print("\(status)")
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
        [
            kSecClass: kSecClassInternetPassword,
            kSecAttrAccessGroup: applicationGroupIdentifier,
            kSecAttrServer: "",
            kSecAttrAccount: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
    }
}

extension KeychainManagerImp: ProtectionStorage {
    var protectionStorageSuffix: String { "_protection" }

    func protection(for database: String) -> QuickUnlockProtection? {
        guard let protectionString = try? item(for: "\(database)\(protectionStorageSuffix)"),
              let data = protectionString.data(using: .utf8),
              let protection = try? JSONDecoder().decode(QuickUnlockProtection.self,
                                                         from: data) else {
            return nil
        }
        return protection
    }

    func setProtection(_ protection: QuickUnlockProtection, for database: String) throws {
        let jsonEncoder = JSONEncoder()
        let protectionData = try jsonEncoder.encode(protection)
        if let protectionString = String(data: protectionData, encoding: .utf8) {
            try setItem(protectionString, for: "\(database)\(protectionStorageSuffix)")
        }
    }

    func deleteProtection(for database: String) throws {
        try deleteItem(for: "\(database)\(protectionStorageSuffix)")
    }
}
