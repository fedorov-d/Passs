//
//  LocalAuthManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.02.2022.
//

import Foundation
import LocalAuthentication

protocol LocalAuthManager: AnyObject {
    var biomeryType: LABiometryType { get }
    func isLocalAuthAvailable() -> Bool
    func saveUnlockData(_ unlockData: UnlockData, for database: String) throws
    func unlockData(for database: String, completion: @escaping (Result<UnlockData, Error>) -> Void)
}

final class LocalAuthManagerImp: LocalAuthManager {

    private let keychainManager: KeychainManager

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }

    var biomeryType: LABiometryType {
        LAContext().biometryType
    }

    func isLocalAuthAvailable() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func saveUnlockData(_ unlockData: UnlockData, for database: String) throws {
        let data = try JSONEncoder().encode(unlockData)
        if let string = String(data: data, encoding: .utf8) {
            try keychainManager.setItem(string, for: database)
        }
    }

    func unlockData(for database: String, completion: @escaping (Result<UnlockData, Error>) -> Void) {
        do {
            guard let string = try keychainManager.item(for: database),
                  let data = string.data(using: .utf8),
                  let unlockData = try? JSONDecoder().decode(UnlockData.self, from: data) else {
                completion(.failure(KeychainError.itemNotFound))
                return
            }
            evaluatePolicy { success, error in
                if success {
                    completion(.success(unlockData))
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
