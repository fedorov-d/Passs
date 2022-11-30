//
//  RootCoordinator.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import UIKit

final class RootCoordinator {
    let navigationController: UINavigationController
    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        self.navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
    }

    func showDatabasesViewController() {
        navigationController.viewControllers = [databaseListViewController()]
    }

    private func showUnlockViewController(for database: StoredDatabase, passDatabaseManager: PassDatabaseManager) {
        let controller = self.unlockViewController(
            for: database,
            passDatabaseManager: passDatabaseManager,
            localAuthManager: self.serviceLocator.localAuthManager()
        )
        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController.present(navigationController, animated: true)
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
            localAuthManager: serviceLocator.localAuthManager(),
            enterPassword: { [weak self] database in
                self?.showUnlockViewController(for: database, passDatabaseManager: passDatabaseManager)
            }
        ) { [weak self] in
            self?.showGroupsViewController(passDatabaseManager: passDatabaseManager)
        }
    }

    private func unlockViewController(
        for database: StoredDatabase,
        passDatabaseManager: PassDatabaseManager,
        localAuthManager: LocalAuthManager
    ) -> UnlockViewController {
        let enterPasswordController = UnlockViewController(
            passDatabaseManager: passDatabaseManager,
            localAuthManager: localAuthManager,
            database: database
        ) { [unowned self] in
            self.navigationController.dismiss(animated: true)
            self.showGroupsViewController(passDatabaseManager: passDatabaseManager)
        }
        return enterPasswordController
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
