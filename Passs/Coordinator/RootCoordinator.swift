//
//  RootCoordinator.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import UIKit

final class RootCoordinator {
    private let window: UIWindow
    let navigationController: UINavigationController
    private let serviceLocator: ServiceLocator

    init(window: UIWindow, serviceLocator: ServiceLocator) {
        self.window = window
        self.serviceLocator = serviceLocator
        self.navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = self.navigationController
        window.makeKeyAndVisible()
    }

    func showDatabasesViewController() {
        navigationController.viewControllers = [databaseListViewController()]
    }

    private func showGroupsViewController(passDatabaseManager: PassDatabaseManager) {
        guard let databaseURL = passDatabaseManager.databaseURL else {
            fatalError()
        }
        let recentPasswordsManager = self.serviceLocator.recentPasswordsManager(databaseURL: databaseURL)
        let groupsViewController = self.groupsViewController(
            passDatabaseManager: passDatabaseManager,
            recentPasswordsManager: recentPasswordsManager
        )
        navigationController.pushViewController(groupsViewController, animated: true)
    }

    private func showPasswordsViewController(for group: PassGroup, recentPasswordsManager: RecentPasswordsManager) {
        let passwordsViewController = self.passwordsViewController(
            for: group,
            recentPasswordsManager: recentPasswordsManager
        )
        navigationController.pushViewController(passwordsViewController, animated: true)
    }
}

extension RootCoordinator {
    private func databaseListViewController() -> DatabaseListViewController {
        let passDatabaseManager = serviceLocator.passDatabaseManager()
        return DatabaseListViewController(
            databasesProvider: serviceLocator.databasesProvider(),
            passDatabaseManager: passDatabaseManager,
            localAuthManager: serviceLocator.localAuthManager()) { [weak self] in
                guard let self = self else { return }
                self.showGroupsViewController(passDatabaseManager: passDatabaseManager)
            }
    }

    private func groupsViewController(
        passDatabaseManager: PassDatabaseManager,
        recentPasswordsManager: RecentPasswordsManager) -> GroupsViewController {
        GroupsViewController(
            databaseManager: passDatabaseManager,
            recentPasswordsManager: recentPasswordsManager,
            searchResultsControllerProvider: {
                PasswordsViewController(
                    pasteboardManager: self.serviceLocator.pasteboardManager(),
                    recentPasswordsManager: recentPasswordsManager
                )
            }) { [unowned self] group in
                self.showPasswordsViewController(for: group, recentPasswordsManager: recentPasswordsManager)
            }
    }

    private func passwordsViewController(
        for group: PassGroup?,
        recentPasswordsManager: RecentPasswordsManager
    ) -> PasswordsViewController {
        PasswordsViewController(
            title: group?.title,
            items: group?.items.sortedByName() ?? [],
            pasteboardManager: serviceLocator.pasteboardManager(),
            recentPasswordsManager: recentPasswordsManager
        )
    }
}
