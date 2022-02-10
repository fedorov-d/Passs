//
//  RecentPasswordsManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 03.02.2022.
//

import Foundation

protocol RecentPasswordsManager {
    func push(item: PassItem)
    func matchingItems(for items: [PassItem]) -> [PassItem]
}

final class RecentPasswordsManagerImp: RecentPasswordsManager {
    private(set) var items: [String] = []
    private let userDefaults = UserDefaults.standard

    private var storageKey: String {
        return databaseURL.lastPathComponent + " " + "recentPasswordItems"
    }

    private let databaseURL: URL

    init(databaseURL: URL) {
        self.databaseURL = databaseURL
        items = userDefaults.object(forKey: storageKey) as? [String] ?? []
    }

    func push(item: PassItem) {
        guard !items.contains(key(for: item)) else { return }
        items.insert(key(for: item), at: 0)
        if items.count > Constants.maxRecentItems {
            items.removeLast()
        }
        userDefaults.set(items, forKey: storageKey)
    }

    func matchingItems(for items: [PassItem]) -> [PassItem] {
        self.items.compactMap { key -> PassItem? in
            items.first { pItem in
                self.key(for: pItem) == key
            }
        }
    }

    private func key(for item: PassItem) -> String {
        return (item.title ?? "") + (item.username ?? "")
    }
}
