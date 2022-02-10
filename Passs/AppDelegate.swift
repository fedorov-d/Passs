//
//  AppDelegate.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    let pasteboardManager: PasteboardManager = PasteboardManagerImp()
    let databasesProvider: DatabasesProvider = DatabasesProviderImp()
    let keychainManager: KeychainManager = KeychainManagerImp()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let options = launchOptions, let launchURL = options[UIApplication.LaunchOptionsKey.url] as? URL {
            do {
                try databasesProvider.addDatabase(from: launchURL)
            } catch (let error) {
                Swift.debugPrint(error)
            }
        }
        
        let navigationController = UINavigationController()
        let databaseListViewController = DatabaseListViewController(
            databasesProvider: databasesProvider,
            localAuthManager: LocalAuthManagerImp(keychainManager: keychainManager)
        ) { [unowned self] databaseURL, password in
            let passDatabaseManager = PassDatabaseManagerImp(
                databaseURL: databaseURL,
                password: password
            )
            let recentPasswordsManager = RecentPasswordsManagerImp(databaseURL: databaseURL)
            let groupsViewController = GroupsViewController(
                databaseManager: passDatabaseManager,
                recentPasswordsManager: recentPasswordsManager,
                searchResultsControllerProvider: {
                    PasswordsViewController(
                        pasteboardManager: self.pasteboardManager,
                        recentPasswordsManager: recentPasswordsManager
                    )
                },
                groupSelected: { [unowned self] group in
                    let passwordsViewController = PasswordsViewController(
                        title: group.title,
                        items: group.items.sortedByName(),
                        pasteboardManager: self.pasteboardManager,
                        recentPasswordsManager: recentPasswordsManager
                    )
                    navigationController.pushViewController(passwordsViewController, animated: true)
                })
            navigationController.pushViewController(groupsViewController, animated: true)
        }
        navigationController.viewControllers = [databaseListViewController]
        navigationController.navigationBar.prefersLargeTitles = true
        window = UIWindow()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        if let application = application as? Application {
            application.onLockout = {
                guard navigationController.viewControllers.count > 1 else { return }
                navigationController.popToRootViewController(animated: false)
            }
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        guard pasteboardManager.needsDropPassword else { return }
        var identifier: UIBackgroundTaskIdentifier? = nil
        identifier = application.beginBackgroundTask {
            self.pasteboardManager.dropPassword {
                if let id = identifier {
                    application.endBackgroundTask(id)
                }
            }
        }
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        do {
            try databasesProvider.addDatabase(from: url)
        } catch (let error) {
            Swift.debugPrint(error)
        }
        return true
    }
}

