//
//  PassDatabaseManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import Foundation
import KeePassKit
import AuthenticationServices

enum PassDatabaseManagerError: Error {
    case cantAccessURL
}

protocol PassDatabaseManager: AnyObject {
    var passwordGroups: [PassGroup]? { get }
    var databaseName: String? { get }
    var databaseURL: URL? { get }

    var isDatabaseUnlocked: Bool { get }
    func unlockDatabase(with url: URL, password: String?, keyFileData: Data?) throws
    func lockDatabase()
}

extension PassItem {
    var serviceIdentifier: ASCredentialServiceIdentifier? {
        guard let title else { return nil }
        if let url, let _ = URL(string: url) {
            return ASCredentialServiceIdentifier(identifier: url,
                                                 type: .URL)
        } else {
            return ASCredentialServiceIdentifier(identifier: title,
                                                 type: .domain)
        }
    }
}

final class PassDatabaseManagerImp: PassDatabaseManager {
    private(set) var passwordGroups: [PassGroup]? {
        didSet {
            // make passwords available in quick type panel
            guard let passwordGroups else { return }
            let store = ASCredentialIdentityStore.shared
            store.getState { state in
                guard state.isEnabled else { return }
                let credentialIdentities = passwordGroups
                    .compactMap { $0.items }
                    .flatMap { $0 }
                    .compactMap { item -> ASPasswordCredentialIdentity? in

                        guard let username = item.username,
                              let serviceIdentifier = item.serviceIdentifier else { return nil }
                        return ASPasswordCredentialIdentity(serviceIdentifier: serviceIdentifier,
                                                            user: username,
                                                            recordIdentifier: item.uuid.uuidString)
                    }
                store.replaceCredentialIdentities(with: credentialIdentities) { success, error in
                    Swift.debugPrint("credentials replaced \(success), \(String(describing: error))")
                }
            }
        }
    }
    private(set) var databaseName: String?
    private(set) var databaseURL: URL? {
        didSet {
            if let databaseURL {
                UserDefaults.shared.set(databaseURL.absoluteURL,
                                        forKey: UserDefaults.Keys.openedDatabaseURL.rawValue)
            } else {
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.openedDatabaseURL.rawValue)
            }
        }
    }

    private var timer: Timer?

    var isDatabaseUnlocked: Bool {
        passwordGroups != nil
    }

    func unlockDatabase(with url: URL, password: String? = nil, keyFileData: Data? = nil) throws {
        guard url.startAccessingSecurityScopedResource() else {
            lockDatabase()
            throw PassDatabaseManagerError.cantAccessURL
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        var keys = [KPKKey]()
        if let password = password {
            keys.append(KPKPasswordKey(password: password)!)
        }
        if let keyFileData = keyFileData {
            keys.append(KPKKey(keyFileData: keyFileData))
        }
        let compositeKey = KPKCompositeKey(keys: keys)
        let tree = try KPKTree(contentsOf: url, key: compositeKey)
        databaseName = tree.root?.title
        databaseURL = url
        passwordGroups = tree.root?.groups.sorted {
            $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
    }

    func lockDatabase() {
        databaseName = nil
        databaseURL = nil
        passwordGroups = nil
    }
}
