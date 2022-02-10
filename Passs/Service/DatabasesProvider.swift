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
    func addDatabase(from url: URL) throws
    func deleteDatabase(_: StoredDatabase)
    var databases: [StoredDatabase] { get }
    var delegate: DatabasesProviderDelegate? { get set }
}

protocol DatabasesProviderDelegate: AnyObject {
    func didAddDatabase(at index: Int)
}

struct StoredDatabaseImp: StoredDatabase {
    let url: URL
    let name: String
    let modificationDate: Date?
}

final class DatabasesProviderImp: DatabasesProvider {

    weak var delegate: DatabasesProviderDelegate?
    
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
                    let attributes = try? fileManager.attributesOfItem(atPath: url.relativePath)
                    let modificationDate = attributes?[.modificationDate] as? Date
                    return StoredDatabaseImp(url: url, name: url.lastPathComponent, modificationDate: modificationDate)
            }
        }
        return []
    }()
    
    let supportedExtensions = ["kdb", "kdbx"]
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
