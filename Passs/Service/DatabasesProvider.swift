//
//  DatabasesProvider.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import Foundation

protocol DatabasesProvider: AnyObject {
    func addDatabase(from url: URL) throws
    func deleteDatabase(at url: URL)
    var databases: [URL] { get }
    var delegate: DatabasesProviderDelegate? { get set }
}

protocol DatabasesProviderDelegate: AnyObject {
    func didAddDatabase(at index: Int)
}

final class DatabasesProviderImp: DatabasesProvider {
    weak var delegate: DatabasesProviderDelegate?

    private let storage = UserDefaults(suiteName: "group.password.storage")

    private(set) lazy var databases: [URL] = {
        let bookmarks = storage?.value(forKey: "storage") as? [Data] ?? []
        return bookmarks.compactMap {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale:&isStale), isStale == false {
                return url
            }
            return nil
        }
    }() {
        didSet {
            let bookmarksArray = databases.compactMap { try? $0.bookmarkData() }
            storage?.setValue(bookmarksArray, forKey: "storage")
        }
    }
    
    func addDatabase(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            Swift.debugPrint("Cannot access security-scoped URL: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        if !databases.contains(url) {
            databases.append(url)
            delegate?.didAddDatabase(at: databases.count - 1)
        }
    }

    func deleteDatabase(at url: URL) {
        if let index = databases.firstIndex(of: url) {
            databases.remove(at: index)
        }
    }

    private func modificationDate(forFileAtPath path: String) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
    }
    
    let supportedExtensions = ["kdb", "kdbx"]
    
    private let documentsURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.password.storage"
    )!
}
