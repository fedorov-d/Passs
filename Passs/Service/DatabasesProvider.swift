//
//  DatabasesProvider.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import Foundation

protocol DatabasesProvider: AnyObject {
    func addDatabase(from url: URL) throws
    func deleteDatabase(at index: Int)
    var databaseURLs: [URL] { get }
    var delegate: DatabasesProviderDelegate? { get set }
}

protocol DatabasesProviderDelegate: AnyObject {
    func didAddDatabase(at index: Int)
    func didDeleteDatabase(at index: Int, name: String)
}

final class DatabasesProviderImp: DatabasesProvider {
    weak var delegate: DatabasesProviderDelegate?

    private let storage = UserDefaults.shared

    private(set) lazy var databaseURLs: [URL] = {
        let bookmarks = storage?.value(forKey: UserDefaults.Keys.storage.rawValue) as? [Data] ?? []
        return bookmarks.compactMap {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale:&isStale), isStale == false {
                return url
            }
            return nil
        }
    }() {
        didSet {
            let bookmarksArray = databaseURLs.compactMap { try? $0.bookmarkData() }
            storage?.setValue(bookmarksArray, forKey: UserDefaults.Keys.storage.rawValue)
        }
    }
    
    func addDatabase(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            Swift.debugPrint("Cannot access security-scoped URL: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard !databaseURLs.contains(url),
              supportedExtensions.contains(url.pathExtension) else { return }
        databaseURLs.append(url)
        delegate?.didAddDatabase(at: databaseURLs.count - 1)
    }

    func deleteDatabase(at index: Int) {
        let removedURL = databaseURLs.remove(at: index)
        delegate?.didDeleteDatabase(at: index, name: removedURL.lastPathComponent)
    }
    
    let supportedExtensions = ["kdb", "kdbx"]
}
