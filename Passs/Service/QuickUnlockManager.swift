//
//  LocalAuthManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.02.2022.
//

import Foundation
import LocalAuthentication

struct QuickUnlockProtection: Codable {
    let passcode: String?
    let biometry: Bool

    init?(passcode: String?, biometry: Bool) {
        guard passcode != nil || biometry == true else { return nil }
        self.passcode = passcode
        self.biometry = biometry
    }
}

protocol QuickUnlockManager: AnyObject {
    var biomeryType: LABiometryType { get }
    @discardableResult
    func isLocalAuthAvailable() -> Bool
    func savedPasscode(for database: String) -> String?
    func saveUnlockData(_ unlockData: UnlockData,
                        protection: QuickUnlockProtection,
                        for database: String) throws
    func clearUnlockData(for database: String) throws
    func unlockData(for database: String,
                    passcodeCheckPassed: @escaping (String, @escaping (Bool) -> Void) -> Void,
                    completion: @escaping (Result<UnlockData, Error>) -> Void)
    var isFetchingUnlockData: Bool { get }
}

final class QuickUnlockManagerImp: QuickUnlockManager {
    private let keychainManager: KeychainManager
    private(set) var isFetchingUnlockData = false

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }

    var biomeryType: LABiometryType {
        LAContext().biometryType
    }

    @discardableResult
    func isLocalAuthAvailable() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func savedPasscode(for database: String) -> String? {
        return protection(for: database)?.passcode
    }

    func saveUnlockData(_ unlockData: UnlockData, protection: QuickUnlockProtection, for database: String) throws {
        let jsonEncoder = JSONEncoder()
        let data = try jsonEncoder.encode(unlockData)
        if let string = String(data: data, encoding: .utf8) {
            try keychainManager.setItem(string, for: database)
        }
        let protectionData = try jsonEncoder.encode(protection)
        if let protectionString = String(data: protectionData, encoding: .utf8) {
            try keychainManager.setItem(protectionString, for: "\(database)_protection")
        }
    }

    func clearUnlockData(for database: String) throws {
        try keychainManager.deleteItem(for: database)
        try? keychainManager.deleteItem(for: "\(database)_protection")
    }

    func unlockData(for database: String,
                    passcodeCheckPassed: @escaping (String, @escaping (Bool) -> Void) -> Void,
                    completion: @escaping (Result<UnlockData, Error>) -> Void) {
        guard !isFetchingUnlockData else { return }
        isFetchingUnlockData = true
        do {
            guard let protection = protection(for: database),
                  let string = try keychainManager.item(for: database),
                  let data = string.data(using: .utf8),
                  let unlockData = try? JSONDecoder().decode(UnlockData.self, from: data) else {
                isFetchingUnlockData = false
                completion(.failure(KeychainError.itemNotFound))
                return
            }

            if let passcode = protection.passcode {
                passcodeCheckPassed(passcode) { passed in

                }
            }
            guard protection.biometry == true else {
                isFetchingUnlockData = false
                completion(.success(unlockData))
                return
            }
            evaluatePolicy { [weak self] success, error in
                guard let self else { return }
                self.isFetchingUnlockData = false
                if success {
                    completion(.success(unlockData))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        } catch let error {
            isFetchingUnlockData = false
            completion(.failure(error))
        }
    }

    private func protection(for database: String) -> QuickUnlockProtection? {
        guard let protectionString = try? keychainManager.item(for: "\(database)_protection"),
              let data = protectionString.data(using: .utf8),
              let protection = try? JSONDecoder().decode(QuickUnlockProtection.self,
                                                         from: data) else {
            return nil
        }
        return protection
    }

    private func evaluatePolicy(completion: @escaping (Bool, Error?) -> Void) {
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Unlock database") { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

}
