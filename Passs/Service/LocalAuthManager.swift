//
//  LocalAuthManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.02.2022.
//

import Foundation
import LocalAuthentication

protocol LocalAuthManager: AnyObject {
    func isLocalAuthAvailable() -> Bool
    func savePassword(_ password: String, for database: String) throws
    func password(for database: String, completion: @escaping (Result<String, Error>) -> Void)
}

final class LocalAuthManagerImp: LocalAuthManager {

    private let keychainManager: KeychainManager

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }

    func isLocalAuthAvailable() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func savePassword(_ password: String, for database: String) throws {
        try keychainManager.setItem(password, for: database)
    }

    func password(for database: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            guard let password = try keychainManager.item(for: database) else {
                completion(.failure(KeychainError.itemNotFound))
                return
            }
            evaluatePolicy { success, error in
                if success {
                    completion(.success(password))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    private func evaluatePolicy(completion: @escaping (Bool, Error?) -> Void) {
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock database") { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

}
