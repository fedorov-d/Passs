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

class LocalAuthManagerImp: LocalAuthManager {

    private let keychainManager: KeychainManager
    private let context: LAContext = {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 5
        return context
    }()

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }

    func isLocalAuthAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
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
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "test") { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(password))
                    } else if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        } catch (let error) {
            completion(.failure(error))
        }
    }

}