//
//  PassDatabaseManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import Foundation
import KeePassKit

protocol PassDatabaseManager: AnyObject {
    var passwordGroups: [PassGroup]? { get }
    var databaseName: String? { get }
    var databaseURL: URL? { get }
    func load(databaseURL: URL, password: String?, keyFileData: Data?) throws
}

final class PassDatabaseManagerImp: PassDatabaseManager {
    private(set) var passwordGroups: [PassGroup]?
    private(set) var databaseName: String?
    private(set) var databaseURL: URL?
    
    func load(databaseURL: URL, password: String? = nil, keyFileData: Data? = nil) throws {
        var keys = [KPKKey]()
        if let password = password {
            keys.append(KPKPasswordKey(password: password)!)
        }
        if let keyFileData = keyFileData {
            keys.append(KPKKey(keyFileData: keyFileData))
        }
        let compositeKey = KPKCompositeKey(keys: keys)
        let tree = try KPKTree(contentsOf: databaseURL, key: compositeKey)
        databaseName = tree.root?.title
        self.databaseURL = databaseURL
        self.passwordGroups = tree.root?.groups.sorted {
            $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
    }
}
