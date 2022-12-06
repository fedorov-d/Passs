//
//  SettingsManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 23.02.2022.
//

import Foundation

final class SettingsManager {
    @UserDefaultsBacked<TimeInterval>(key: "clearPasteboardTimeInterval")
    var clearPasteboardTimeInterval

    @UserDefaultsBacked<TimeInterval>(key: "closeDatabaseTimeInterval")
    var closeDatabaseTimeInterval

    @UserDefaultsBacked<Int>(key: "maxRecentItems")
    var maxRecentItems


}
