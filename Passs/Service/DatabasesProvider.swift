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
    func didUpdateDatabase(at index: Int)
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
                    let modificationDate = self.modificationDate(forItem: url.relativePath)
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
        if fileManager.fileExists(atPath: fURL.relativePath) {
            let tmpURL = fURL.appendingPathExtension("tmp")
            try? fileManager.removeItem(at: tmpURL)
            try fileManager.copyItem(at: url, to: tmpURL)
            // update older file with newer but not vice versa
            guard let oldFileDate = modificationDate(forItem: fURL.relativePath),
                  let newFileDate = modificationDate(forItem: tmpURL.relativePath) else { return }
            if newFileDate > oldFileDate {
                try fileManager.removeItem(at: fURL)
                try fileManager.moveItem(at: tmpURL, to: fURL)
                let updatedDatabase = StoredDatabaseImp(url: fURL, name: filename, modificationDate: newFileDate)
                guard let indexOfUpdatedDatabase = self.databases.firstIndex(where: { database in
                    database.name == fURL.lastPathComponent
                }) else { fatalError() }
                self.databases[indexOfUpdatedDatabase] = updatedDatabase
                self.delegate?.didUpdateDatabase(at: indexOfUpdatedDatabase)
            } else {
                try? fileManager.removeItem(at: tmpURL)
            }
        } else {
            try fileManager.copyItem(at: url, to: fURL)
            let date = modificationDate(forItem: fURL.relativePath)
            databases.append(StoredDatabaseImp(url: fURL, name: filename, modificationDate: date))
            delegate?.didAddDatabase(at: databases.count - 1)
        }
    }

    func deleteDatabase(_ database: StoredDatabase) {
        if (try? FileManager.default.removeItem(at: database.url)) != nil,
           let index = databases.firstIndex(where: { $0.url == database.url }) {
            databases.remove(at: index)
        }
    }

    private func modificationDate(forItem path: String) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
    }
    
    private(set) var databases: [StoredDatabase] = []
    
    let supportedExtensions = ["kdb", "kdbx"]
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
