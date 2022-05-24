//
//  SettingsManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 23.02.2022.
//

import Foundation

class SettingsManager {

    @UserDefaultsBacked<TimeInterval>(key: "clearPasteboardTimeIntervaln")
    var clearPasteboardTimeInterval

    @UserDefaultsBacked<TimeInterval>(key: "closeDatabaseTimeInterval")
    var closeDatabaseTimeInterval

    @UserDefaultsBacked<Int>(key: "maxRecentItems")
    var maxRecentItems


}
