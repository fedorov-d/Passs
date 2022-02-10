//
//  PassDatabaseManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import Foundation
import KeePassKit

protocol PassDatabaseManager {
    var passwordGroups: [PassGroup]? { get }
    var databaseName: String? { get }
    var databaseURL: URL? { get }
    func load(databaseURL: URL, password: String) throws
}

final class PassDatabaseManagerImp: PassDatabaseManager {
    private(set) var passwordGroups: [PassGroup]?
    private(set) var databaseName: String?
    private(set) var databaseURL: URL?
    
    func load(databaseURL: URL, password: String) throws {
        let key = KPKPasswordKey(password: password)!
        let compositeKey = KPKCompositeKey(keys: [key])
        let tree = try KPKTree(contentsOf: databaseURL, key: compositeKey)
        databaseName = tree.root?.title
        self.databaseURL = databaseURL
        if let groups = tree.root?.groups {
            self.passwordGroups = groups.sorted(by: {
                $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            })
        }
    }
}
