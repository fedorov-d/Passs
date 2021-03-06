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
                try serviceLocator.databasesProvider().addDatabase(from: launchURL)
            } catch (let error) {
                Swift.debugPrint(error)
            }
        }
        window = UIWindow()
        coordinator = RootCoordinator(window: window!, serviceLocator: serviceLocator)
        coordinator?.showDatabasesViewController()
        if let application = application as? Application {
            application.onLockout = { [unowned self] in
                coordinator?.showDatabasesViewController()
            }
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        guard serviceLocator.pasteboardManager().needsDropPassword else { return }
        var identifier: UIBackgroundTaskIdentifier? = nil
        identifier = application.beginBackgroundTask {
            self.serviceLocator.pasteboardManager().dropPassword {
                guard let id = identifier else { return }
                application.endBackgroundTask(id)
            }
        }
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        do {
            try self.serviceLocator.databasesProvider().addDatabase(from: url)
        } catch (let error) {
            Swift.debugPrint(error)
        }
        return true
    }

    func isLineContainsZeroSum(_ line: String, count: Int) -> Bool {
        let arrayOfChars = Array(line.components(separatedBy: " ").prefix(count))
        var sum = 0
        for char in arrayOfChars {
            let intValue = Int(char) ?? 0
            if intValue == 0 {
                return true
            }
            sum += intValue
            if sum == 0 {
                return true
            }
        }
        for char in Array(arrayOfChars.prefix(arrayOfChars.count - 1)) {
            let intValue = Int(char) ?? 0
            sum -= intValue
            if sum == 0 {
                return true
            }
        }
        return false
    }
}
