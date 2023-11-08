//
//  SettingsManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 23.02.2022.
//

import Foundation

protocol DefaultDatabaseObserver: AnyObject {
    func defaultDataBaseDidChange()
}

final class SettingsManager {
    weak var defaultDatabaseObserver: DefaultDatabaseObserver?

    @UserDefaultsBacked<TimeInterval>(key: "clearPasteboardTimeInterval")
    var clearPasteboardTimeInterval

    @UserDefaultsBacked<TimeInterval>(key: "closeDatabaseTimeInterval")
    var closeDatabaseTimeInterval

    @UserDefaultsBacked<Int>(key: "maxRecentItems")
    var maxRecentItems

    @UserDefaultsBacked<String>(key: "defaultDatabaseURLString")
    var defaultDatabaseURLString

    var defaultDatabaseURL: URL? {
        get { defaultDatabaseURLString.flatMap { URL(string: $0) }}
        set {
            defaultDatabaseURLString = newValue?.absoluteString
            defaultDatabaseObserver?.defaultDataBaseDidChange()
        }
    }
}
