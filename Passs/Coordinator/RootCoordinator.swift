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

    func showDatabasesViewController(onCancel: (() -> Void)? = nil) {
        navigationController.viewControllers = [databaseListViewController(onCancel: onCancel)]
    }

    private func showUnlockViewController(forDatabaseAt url: URL, passDatabaseManager: PassDatabaseManager) {
        let controller = self.unlockViewController(
            forDatabaseAt: url,
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
    private func databaseListViewController(onCancel: (() -> Void)? = nil) -> DatabaseListViewController {
        let passDatabaseManager = serviceLocator.passDatabaseManager()
        return DatabaseListViewController(
            databasesProvider: serviceLocator.databasesProvider,
            passDatabaseManager: passDatabaseManager,
            localAuthManager: serviceLocator.localAuthManager(),
            onAskForPassword: { [weak self] url in
                self?.showUnlockViewController(forDatabaseAt: url, passDatabaseManager: passDatabaseManager)
            },
            onDatabaseOpened: { [weak self] in
                self?.showGroupsViewController(passDatabaseManager: passDatabaseManager)
            },
            onCancel: onCancel
        )
    }

    private func unlockViewController(
        forDatabaseAt url: URL,
        passDatabaseManager: PassDatabaseManager,
        localAuthManager: LocalAuthManager
    ) -> UnlockViewController {
        let enterPasswordController = UnlockViewController(
            passDatabaseManager: passDatabaseManager,
            localAuthManager: localAuthManager,
            forDatabaseAt: url
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
                    pasteboardManager: self.serviceLocator.pasteboardManager,
                    recentPasswordsManager: recentPasswordsManager,
                    credentialsSelectionManager: self.serviceLocator.credentialsSelectionManager
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
            pasteboardManager: serviceLocator.pasteboardManager,
            recentPasswordsManager: recentPasswordsManager,
            credentialsSelectionManager: serviceLocator.credentialsSelectionManager
        )
    }
}

extension RootCoordinator: DefaultDatabaseUnlock {
    func unlockDatabaseIfNeeded() {
        guard let actualUnlock = navigationController.viewControllers.first(where: {
            $0 as? DefaultDatabaseUnlock != nil }
        ) as? DefaultDatabaseUnlock else { return }
        actualUnlock.unlockDatabaseIfNeeded()
    }
}
