//
//  RootCoordinator.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import SwiftUI

final class RootCoordinator {
    let navigationController: UINavigationController
    private let serviceLocator: ServiceLocator

#if !CREDENTIALS_PROVIDER_EXTENSION
    private var appSwitcherViewController: AppSwitcherOverlayViewController?
    func showAppSwitcherOverlayViewController() {
        guard navigationController.viewControllers.count > 1 else { return }
        let appSwitcherViewController = AppSwitcherOverlayViewController()
        navigationController.present(appSwitcherViewController, animated: true)
        self.appSwitcherViewController = appSwitcherViewController
    }

    func hideAppSwithcherOverlayViewController() {
        appSwitcherViewController?.dismiss(animated: true)
        appSwitcherViewController = nil
    }
#endif

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        self.navigationController = UINavigationController(navigationBarClass: ProgressNavigationBar.self,
                                                           toolbarClass: nil)
        if let navigationBar = navigationController.navigationBar as? ProgressNavigationBar {
            serviceLocator.pasteboardManager.delegate = navigationBar
        }
        navigationController.navigationBar.prefersLargeTitles = true
    }

    func showDatabasesViewController(animated: Bool = true) {
        switch self.navigationController.viewControllers.count {
        case 0:
            navigationController.viewControllers = [databaseListViewController()]
        case 1..<Int.max:
            navigationController.popToRootViewController(animated: animated)
            navigationController.presentedViewController?.dismiss(animated: animated)
        default: break
        }
    }

    private func showUnlockViewController(forDatabaseAt url: URL, passDatabaseManager: PassDatabaseManager) {
        let unlockViewController = self.unlockViewController(
            forDatabaseAt: url,
            passDatabaseManager: passDatabaseManager,
            localAuthManager: self.serviceLocator.quickUnlockManager()
        )
        let navigationController = UINavigationController(navigationBarClass: ProgressNavigationBar.self,
                                                          toolbarClass: nil)
        navigationController.viewControllers = [unlockViewController]
        self.navigationController.present(navigationController, animated: true)
    }

    private func showGroupsViewController(passDatabaseManager: PassDatabaseManager) {
        let groupsViewController = self.groupsViewController(passDatabaseManager: passDatabaseManager)
        navigationController.pushViewController(groupsViewController, animated: true)
    }

    private func showPasswordsViewController(title: String? = nil,
                                             footerViewProvider: (() -> UIView)? = nil,
                                             sectionTitle: String? = nil,
                                             items: [PassItem],
                                             recentPasswordsManager: RecentPasswordsManager) {
        let passwordsViewController = self.passwordsViewController(title: title,
                                                                   footerViewProvider: footerViewProvider,
                                                                   sectionTitle: sectionTitle,
                                                                   items: items,
                                                                   recentPasswordsManager: recentPasswordsManager)
        navigationController.pushViewController(passwordsViewController, animated: true)
    }

    private func showPasswordDetailsViewController(_ passItem: PassItem) {
        let passwordDetailsViewController = PasswordDetailsViewController(
            passItem: passItem,
            pasteboardManager: serviceLocator.pasteboardManager
        )
        navigationController.pushViewController(passwordDetailsViewController, animated: true)
    }

    private func showDatabaseSettingsViewController(for database: String) {
        let databaseSettingsViewController = DatabaseSettingsViewController(
            quickUnlockManager: serviceLocator.quickUnlockManager(),
            database: database
        )
        let modalNavigationController = UINavigationController(rootViewController: databaseSettingsViewController)
        navigationController.present(modalNavigationController, animated: true)
    }
}

extension RootCoordinator {
    private func databaseListViewController() -> DatabaseListViewController {
        let passDatabaseManager = serviceLocator.passDatabaseManager()
        return DatabaseListViewController(
            databasesProvider: serviceLocator.databasesProvider,
            passDatabaseManager: passDatabaseManager,
            localAuthManager: serviceLocator.quickUnlockManager(),
            credentialsSelectionManager: serviceLocator.credentialsSelectionManager,
            settingsManager: serviceLocator.settingsManager(),
            onAskForPassword: { [weak self] url in
                self?.showUnlockViewController(forDatabaseAt: url, passDatabaseManager: passDatabaseManager)
            },
            onDatabaseOpened: { [weak self] in
                self?.proceedToUnlocked(passDatabaseManager: passDatabaseManager)
            }
        )
    }

    private func unlockViewController(forDatabaseAt url: URL,
                                      passDatabaseManager: PassDatabaseManager,
                                      localAuthManager: QuickUnlockManager) -> UnlockViewController {
        let enterPasswordController = UnlockViewController(
            passDatabaseManager: passDatabaseManager,
            localAuthManager: localAuthManager,
            forDatabaseAt: url
        ) { [weak self] in
            guard let self else { return }
            self.navigationController.dismiss(animated: true)
            self.proceedToUnlocked(passDatabaseManager: passDatabaseManager)
        }
        return enterPasswordController
    }

    private func groupsViewController(passDatabaseManager: PassDatabaseManager) -> GroupsViewController {
        guard let databaseURL = passDatabaseManager.databaseURL else {
            fatalError()
        }
        let recentPasswordsManager = serviceLocator.recentPasswordsManager(databaseURL: databaseURL)
        return GroupsViewController(
            databaseManager: passDatabaseManager,
            recentPasswordsManager: recentPasswordsManager,
            credentialsSelectionManager: serviceLocator.credentialsSelectionManager,
            searchResultsControllerProvider: { [weak self] in
                guard let self else { fatalError() }
                return PasswordsViewController(
                    onItemSelect: { passItem in
                        self.showPasswordDetailsViewController(passItem)
                    },
                    pasteboardManager: self.serviceLocator.pasteboardManager,
                    recentPasswordsManager: recentPasswordsManager,
                    credentialsSelectionManager: self.serviceLocator.credentialsSelectionManager
                )
            }, groupSelected: { [weak self] group in
                self?.showPasswordsViewController(title: group.title,
                                                  items: group.items,
                                                  recentPasswordsManager: recentPasswordsManager)
            }, settingsSelected: { [weak self] in
                self?.showDatabaseSettingsViewController(for: databaseURL.lastPathComponent)
            })
    }

    private func passwordsViewController(title: String? = nil,
                                         footerViewProvider: (() -> UIView)? = nil,
                                         sectionTitle: String? = nil,
                                         items: [PassItem],
                                         recentPasswordsManager: RecentPasswordsManager) -> PasswordsViewController {
        PasswordsViewController(
            title: title,
            footerViewProvider: footerViewProvider,
            sectionTitle: sectionTitle,
            items: items.sortedByName(),
            onItemSelect: { [weak self] item in
                self?.showPasswordDetailsViewController(item)
            },
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

    func proceedToUnlocked(passDatabaseManager: PassDatabaseManager) {
        if let credentialsSelectionManager = serviceLocator.credentialsSelectionManager,
           let passwords = passDatabaseManager.passwordGroups?.flatMap({ $0.items }),
           let matchingItems = credentialsSelectionManager.matchigItems(for: passwords),
           let databaseURL = passDatabaseManager.databaseURL,
           !matchingItems.isEmpty {
            let recentPasswordsManager = self.serviceLocator.recentPasswordsManager(databaseURL: databaseURL)
            let sectionTitle = (credentialsSelectionManager.serviceIdentifiersStrings?.joined(separator: ","))
                .flatMap { "Entries matching \($0)" }
            self.showPasswordsViewController(
                title: "Passwords",
                footerViewProvider: {
                    let browseDatabaseView = BrowseDatabaseTableHeaderView()
                    browseDatabaseView.buttonAction = { [weak self] in
                        self?.showGroupsViewController(passDatabaseManager: passDatabaseManager)
                    }
                    return browseDatabaseView
                },
                sectionTitle: sectionTitle,
                items: matchingItems,
                recentPasswordsManager: recentPasswordsManager)
        } else {
            self.showGroupsViewController(passDatabaseManager: passDatabaseManager)
        }
    }
}
