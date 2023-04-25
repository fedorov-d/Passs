//
//  ServiceLocator.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import Foundation
import UIKit

protocol ServiceLocator: AnyObject {
    var databasesProvider: DatabasesProvider { get }
    var pasteboardManager: PasteboardManager { get }
    var credentialsSelectionManager: CredentialsSelectionManager? { get }

    func keychainManager() -> KeychainManager
    func localAuthManager() -> LocalAuthManager
    func passDatabaseManager() -> PassDatabaseManager
    func recentPasswordsManager(databaseURL: URL) -> RecentPasswordsManager
    func settingsManager() -> SettingsManager
    func qrCodeManager() -> QRCodeManager
}

final class ServiceLocatorImp: ServiceLocator {
    private let _databasesProvider = DatabasesProviderImp()
    private let _pasteboardManager = PasteboardManagerImp()
    private let _passDatabaseManager = PassDatabaseManagerImp()
    private(set) var _credentialsSelectionManager: CredentialsSelectionManagerImp?

    var databasesProvider: DatabasesProvider {
        _databasesProvider
    }

    var pasteboardManager: PasteboardManager {
        _pasteboardManager
    }

    var credentialsSelectionManager: CredentialsSelectionManager? {
        _credentialsSelectionManager
    }

    func keychainManager() -> KeychainManager {
        KeychainManagerImp()
    }

    func localAuthManager() -> LocalAuthManager {
        LocalAuthManagerImp(keychainManager: keychainManager())
    }

    func passDatabaseManager() -> PassDatabaseManager {
        _passDatabaseManager
    }

    func recentPasswordsManager(databaseURL: URL) -> RecentPasswordsManager {
        RecentPasswordsManagerImp(databaseURL: databaseURL)
    }

    func settingsManager() -> SettingsManager {
        SettingsManager()
    }

    func qrCodeManager() -> QRCodeManager {
        QRCodeManager()
    }

    func makeCredentialsSelectionManager(onCredentialsSelected: @escaping (PassItem) -> Void,
                                         onCancel: @escaping () -> Void)  {
        _credentialsSelectionManager = CredentialsSelectionManagerImp(onCredentialsSelected: onCredentialsSelected,
                                                                      onCancel: onCancel)
    }
}
