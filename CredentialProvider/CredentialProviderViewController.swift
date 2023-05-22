//
//  CredentialProviderViewController.swift
//  CredentialProvider
//
//  Created by Dmitry Fedorov on 05.02.2022.
//

import AuthenticationServices
import SnapKit

class CredentialProviderViewController: ASCredentialProviderViewController {
    private let serviceLocator = ServiceLocatorImp()
    private lazy var coordinator = RootCoordinator(serviceLocator: serviceLocator)

    override func prepareInterfaceForExtensionConfiguration() {
        let store = ASCredentialIdentityStore.shared
        store.getState { state in
            if state.isEnabled {
                // Add, remove, or update identities.
            }
        }
    }

    override func loadView() {
        view = UIView()
        view.tintColor = .keepCyan
    }

    override func viewDidLoad() {
        serviceLocator.makeCredentialsSelectionManager { [weak self] credentials in
            guard let self,
                  let user = credentials.username,
                  let password = credentials.password else { return }
            let passwordCredential = ASPasswordCredential(user: user, password: password)
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } onCancel: { [weak self] in
            self?.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain,
                                                                    code: ASExtensionError.userCanceled.rawValue))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coordinator.unlockDatabaseIfNeeded()
    }
    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
    */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        serviceLocator.credentialsSelectionManager?.serviceIdentifiers = serviceIdentifiers
        let childViewController = coordinator.navigationController
        childViewController.embed(in: self)
        childViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        coordinator.showDatabasesViewController()
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.


    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let userInteractionRequiredFallback = {
            self.extensionContext.cancelRequest(
                withError: NSError(domain: ASExtensionErrorDomain,
                                   code:ASExtensionError.userInteractionRequired.rawValue)
            )
        }
        let currentTimestamp = Date().timeIntervalSince1970

        guard let openedDatabaseURL = UserDefaults.shared.object(
            forKey: UserDefaults.Keys.openedDatabaseURL.rawValue
        ).flatMap({ urlString -> URL? in
            guard let urlString = urlString as? String else { return nil }
            return URL(string: urlString)
        }),
            let enterBackgroundTimestamp = UserDefaults.standard.value(
            forKey: UserDefaults.Keys.enterBackgroundTimestamp.rawValue
        ) as? TimeInterval, (currentTimestamp - enterBackgroundTimestamp) < Constants.closeDatabaseTimeInterval else {
            userInteractionRequiredFallback()
            return
        }
        let quickUnlockManager = serviceLocator.quickUnlockManager()
        let passDatabaseManager = serviceLocator.passDatabaseManager()
        quickUnlockManager.unlockData(for: openedDatabaseURL.lastPathComponent) { result in
            switch result {
            case .success(let success):
                do {
                    try passDatabaseManager.unlockDatabase(with: openedDatabaseURL,
                                                           password: success.password,
                                                           keyFileData: success.keyFileData)
                    let items = passDatabaseManager.passwordGroups?.flatMap { $0.items }
                    if let matchingItem = items?.first(
                        where: { $0.uuid.uuidString == credentialIdentity.recordIdentifier }
                    ), let password = matchingItem.password {
                        let passwordCredential = ASPasswordCredential(user: credentialIdentity.user,
                                                                      password: password)

                        self.extensionContext.completeRequest(withSelectedCredential: passwordCredential,
                                                              completionHandler: nil)
                    } else {
                        userInteractionRequiredFallback()
                    }
                } catch {
                    userInteractionRequiredFallback()
                }
            case .failure(let failure):
                userInteractionRequiredFallback()
            }
        }
    }
     */

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.
     */

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        let childViewController = coordinator.navigationController
        childViewController.embed(in: self)
        childViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        coordinator.showDatabasesViewController()
    }
}
