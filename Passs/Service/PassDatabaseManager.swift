//
//  PassDatabaseManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import Foundation
import KeePassKit

class PassDatabaseManager {
    private(set) var passwordGroups = [PassGroup]()
    private(set) var databaseName: String?
    
    private let databaseURL: URL
    private var password: String?
    
    init(databaseURL: URL, password: String) {
        self.databaseURL = databaseURL
        self.password = password
    }
    
    func load() {
        let key = KPKPasswordKey(password: password)!
        let compositeKey = KPKCompositeKey(keys: [key])
        let tree = try? KPKTree(contentsOf: databaseURL, key: compositeKey)
        databaseName = tree?.root?.title
        if let groups = tree?.root?.groups {
            self.passwordGroups = groups
        }
        self.password = nil
    }
}
