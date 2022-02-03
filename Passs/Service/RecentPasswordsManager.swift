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

class RecentPasswordsManagerImp: RecentPasswordsManager {
    private(set) var items: [PassItem] = []

    func push(item: PassItem) {
        items.insert(item, at: 0)
        if items.count > 5 {
            items.removeLast()
        }
    }

    func matchingItems(for items: [PassItem]) -> [PassItem] {
        self.items.compactMap { passItem -> PassItem? in
            items.first { pItem in
                pItem.title == passItem.title && pItem.username == passItem.username
            }
        }
    }
}
