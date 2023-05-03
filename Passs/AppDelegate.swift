//
//  AppDelegate.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var coordinator: RootCoordinator?
    private var serviceLocator = ServiceLocatorImp()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let options = launchOptions,
           let launchURL = options[UIApplication.LaunchOptionsKey.url] as? URL {
            do {
                try serviceLocator.databasesProvider.addDatabase(from: launchURL)
            } catch (let error) {
                Swift.debugPrint(error)
            }
        }
        coordinator = RootCoordinator(serviceLocator: serviceLocator)
        window = UIWindow()
        window?.rootViewController = coordinator?.navigationController
        window?.makeKeyAndVisible()
        coordinator?.showDatabasesViewController()
        if let application = application as? Application {
            application.onLockout = { [unowned self] in
                coordinator?.showDatabasesViewController()
            }
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveTimestamp()
        beginClearPasteboardBackgroundTaskIfNeeded(application)
    }

    private func beginClearPasteboardBackgroundTaskIfNeeded(_ application: UIApplication) {
        let pasteboardManager = serviceLocator.pasteboardManager
        guard pasteboardManager.needsDropPassword else { return }
        var clearPasteboardTaskIdentifier: UIBackgroundTaskIdentifier? = nil
        clearPasteboardTaskIdentifier = application
            .beginBackgroundTask(withName: "clear.pasteboard") { [pasteboardManager] in
                pasteboardManager.clearPasteboard {
                    guard let clearPasteboardTaskIdentifier else { return }
                    application.endBackgroundTask(clearPasteboardTaskIdentifier)
                }
            }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let enterBackgroundTimestamp = UserDefaults.standard.value(
            forKey: UserDefaults.Keys.enterBackgroundTimestamp.rawValue
        ) as? TimeInterval else { return }
        deleteTimestamp()
        let currentTimestamp = Date().timeIntervalSince1970
        if (currentTimestamp - enterBackgroundTimestamp) > Constants.closeDatabaseTimeInterval {
            coordinator?.showDatabasesViewController()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        deleteTimestamp()
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            try self.serviceLocator.databasesProvider.addDatabase(from: url)
        } catch (let error) {
            Swift.debugPrint(error)
        }
        return true
    }

    private func saveTimestamp() {
        UserDefaults.shared.setValue(Date().timeIntervalSince1970,
                                     forKey: UserDefaults.Keys.enterBackgroundTimestamp.rawValue)
    }

    private func deleteTimestamp() {
        UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.enterBackgroundTimestamp.rawValue)
    }
}
