//
//  DatabasesProvider.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import Foundation

protocol StoredDatabase {
    var url: URL { get }
    var name: String { get }
}

protocol DatabasesProvider {
    func addDatabase(from url: URL) throws
    func deleteDatabase(_: StoredDatabase)
    var databases: [StoredDatabase] { get }
}

class DatabasesProviderImp: DatabasesProvider {
    func addDatabase(from url: URL) throws { 
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try FileManager.default.copyItem(at: url, to: documentsURL)
        }
    }
    
    func deleteDatabase(_: StoredDatabase) {
        
    }
    
    var databases: [StoredDatabase]
    
    init() {
        databases = []
    }
    
    
}
