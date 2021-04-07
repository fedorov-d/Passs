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
    let pasteboardManager:PasteboardManager = PasteboardManagerImp()
    let databasesProvider:DatabasesProvider = DatabasesProviderImp()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if let options = launchOptions, let launchURL = options[UIApplication.LaunchOptionsKey.url] as? URL {
            try? databasesProvider.addDatabase(from: launchURL)
        }
        
        
        let databaseListViewController = DatabaseListViewController(databasesProvider: databasesProvider)
        let navigationController = UINavigationController(rootViewController: databaseListViewController)
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("test")
        return true
    }

}

