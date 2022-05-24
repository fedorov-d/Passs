//
//  ServiceLocator.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import Foundation
import UIKit

protocol ServiceLocator: AnyObject {
    func databasesProvider() -> DatabasesProvider
    func keychainManager() -> KeychainManager
    func localAuthManager() -> LocalAuthManager
    func passDatabaseManager() -> PassDatabaseManager
    func recentPasswordsManager(databaseURL: URL) -> RecentPasswordsManager
    func pasteboardManager() -> PasteboardManager
    func settingsManager() -> SettingsManager
}

final class ServiceLocatorImp: ServiceLocator {

    private let _databasesProvider = DatabasesProviderImp()
    private let _pasteboardManager = PasteboardManagerImp()

    func databasesProvider() -> DatabasesProvider {
        _databasesProvider
    }

    func keychainManager() -> KeychainManager {
        KeychainManagerImp()
    }

    func localAuthManager() -> LocalAuthManager {
        LocalAuthManagerImp(keychainManager: keychainManager())
    }

    func passDatabaseManager() -> PassDatabaseManager {
        PassDatabaseManagerImp()
    }

    func recentPasswordsManager(databaseURL: URL) -> RecentPasswordsManager {
        RecentPasswordsManagerImp(databaseURL: databaseURL)
    }

    func pasteboardManager() -> PasteboardManager {
        _pasteboardManager
    }

    func settingsManager() -> SettingsManager {
        SettingsManager()
    }
}
