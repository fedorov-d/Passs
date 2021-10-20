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

struct StoredDatabaseImp: StoredDatabase {
    var url: URL
    var name: String
}

class DatabasesProviderImp: DatabasesProvider {
    
    func addDatabase(from url: URL) throws {
        let filename = url.lastPathComponent
        let fURL = documentsURL.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: url, to: fURL)
        databases.append(StoredDatabaseImp(url: fURL, name: filename))
    }
    
    func deleteDatabase(_ database: StoredDatabase) {
        if let _ = try? FileManager.default.removeItem(at: database.url),
           let index = databases.firstIndex(where: { $0.url == database.url }) {
            databases.remove(at: index)
        }
    }
    
    lazy var databases: [StoredDatabase] = {
        let fileManager = FileManager.default
        if let fileURLs = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            return fileURLs
                .filter { $0.isFileURL && supportedExtensions.contains($0.pathExtension) }
                .map { url in
                StoredDatabaseImp(url: url, name: url.lastPathComponent)
            }
        }
        return []
    }()
    
    let supportedExtensions = ["kdb", "kdbx"]
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
