//
//  AppDelegate.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let pasteboardManager = PasteboardManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let passwordsViewController = PasswordsViewController(databaseManager: PassDatabaseManager(databaseURL: URL(string: "")!, password: ""), pasteboardManager: pasteboardManager)
        let navigationController = UINavigationController(rootViewController: passwordsViewController)
        window = UIWindow()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        var identifier: UIBackgroundTaskIdentifier? = nil
        identifier = application.beginBackgroundTask {
            self.pasteboardManager.dropPasswordIfNeeded {
                if let id = identifier {
                    application.endBackgroundTask(id)
                }
            }
        }
    }

}

