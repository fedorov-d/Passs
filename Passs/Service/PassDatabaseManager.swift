//
//  PassDatabaseManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import Foundation
import KeePassKit

enum PassDatabaseManagerError: Error {
    case cantAccessURL
}

protocol PassDatabaseManager: AnyObject {
    var passwordGroups: [PassGroup]? { get }
    var databaseName: String? { get }
    var databaseURL: URL? { get }

    func unlockDatabase(with url: URL, password: String?, keyFileData: Data?) throws
    func lockDatabase()
    var isDatabaseUnlocked: Bool { get }
}

final class PassDatabaseManagerImp: PassDatabaseManager {
    private(set) var passwordGroups: [PassGroup]?
    private(set) var databaseName: String?
    private(set) var databaseURL: URL?
    
    func unlockDatabase(with url: URL, password: String? = nil, keyFileData: Data? = nil) throws {
        guard url.startAccessingSecurityScopedResource() else {
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
        self.databaseURL = url
        self.passwordGroups = tree.root?.groups.sorted {
            $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
    }

    func lockDatabase() {
        databaseName = nil
        databaseURL = nil
        passwordGroups = nil
    }

    var isDatabaseUnlocked: Bool {
        passwordGroups != nil
    }
}
