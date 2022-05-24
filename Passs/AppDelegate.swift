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


        let input = """
3
4
2 8 -9 1
10
2 1 3 4 -9 6 8 9 -100000 123132131
4
-5 8 0 4
"""

        let arrayOfLines = input.components(separatedBy: "\n")
        guard let firstLine = arrayOfLines.first else { fatalError() }
        let numberOfTestCases = Int(firstLine) ?? 0

        var currentLineIndex = 1
        var output = [String]()

        for _ in 0..<numberOfTestCases {
            let numberOfItemsInLine = Int(arrayOfLines[currentLineIndex]) ?? 0
            if isLineContainsZeroSum(arrayOfLines[currentLineIndex + 1], count: numberOfItemsInLine) {
                output.append("yes")
            } else {
                output.append("false")
            }
            currentLineIndex += 2
        }

        print(output)

        if let options = launchOptions, let launchURL = options[UIApplication.LaunchOptionsKey.url] as? URL {
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
