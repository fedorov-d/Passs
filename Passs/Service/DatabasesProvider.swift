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
    var modificationDate: Date? { get }
}

protocol DatabasesProvider: AnyObject {
    func loadStoredDatabases()
    func addDatabase(from url: URL) throws
    func deleteDatabase(_: StoredDatabase)
    var databases: [StoredDatabase] { get }
    var delegate: DatabasesProviderDelegate? { get set }
}

protocol DatabasesProviderDelegate: AnyObject {
    func didLoadStoredDatabases()
    func didAddDatabase(at index: Int)
}

struct StoredDatabaseImp: StoredDatabase {
    let url: URL
    let name: String
    let modificationDate: Date?
}

final class DatabasesProviderImp: DatabasesProvider {

    weak var delegate: DatabasesProviderDelegate?

    func loadStoredDatabases() {
        let fileManager = FileManager.default
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        var databases: [StoredDatabase] = []
        OperationQueue().addOperation { [weak self] in
            guard let self = self else { return }
            databases = fileURLs
                .filter { $0.isFileURL && self.supportedExtensions.contains($0.pathExtension) }
                .map { url in
                    let attributes = try? fileManager.attributesOfItem(atPath: url.relativePath)
                    let modificationDate = attributes?[.modificationDate] as? Date
                    return StoredDatabaseImp(url: url, name: url.lastPathComponent, modificationDate: modificationDate)
                }
            OperationQueue.main.addOperation {
                self.databases = databases
                self.delegate?.didLoadStoredDatabases()
            }
        }
    }
    
    func addDatabase(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            Swift.debugPrint("Cannot access security-scoped URL: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        let filename = url.lastPathComponent
        let fURL = documentsURL.appendingPathComponent(filename)
        let fileManager = FileManager.default
        try fileManager.copyItem(at: url, to: fURL)
        let attributes = try? fileManager.attributesOfItem(atPath: fURL.relativePath)
        let date = attributes?[.modificationDate] as? Date
        databases.append(StoredDatabaseImp(url: fURL, name: filename, modificationDate: date))
        delegate?.didAddDatabase(at: databases.count - 1)
    }
    
    func deleteDatabase(_ database: StoredDatabase) {
        if (try? FileManager.default.removeItem(at: database.url)) != nil,
           let index = databases.firstIndex(where: { $0.url == database.url }) {
            databases.remove(at: index)
        }
    }
    
    private(set) var databases: [StoredDatabase] = []
    
    let supportedExtensions = ["kdb", "kdbx"]
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
