//
//  CredentialsSelectionManager.swift
//  Passs
//
//  Created by Dmitry on 01.12.2022.
//

import Foundation
import AuthenticationServices

protocol CredentialsSelectionManager: AnyObject {
    var serviceIdentifiers: [ASCredentialServiceIdentifier]? { get set }
    var serviceIdentifiersStrings: [String]? { get }
    var onCredentialsSelected: ((PassItem) -> Void) { get }
    var onCancel: (() -> Void) { get }
    func matchigItems(for items: [PassItem]) -> [PassItem]?
}

final class CredentialsSelectionManagerImp: CredentialsSelectionManager {
    var serviceIdentifiers: [ASCredentialServiceIdentifier]?

    let onCredentialsSelected: (PassItem) -> Void
    let onCancel: () -> Void

    var serviceIdentifiersStrings: [String]? {
        serviceIdentifiers?.compactMap{ $0.identifier }
    }

    init(onCredentialsSelected: @escaping (PassItem) -> Void,
         onCancel: @escaping () -> Void) {
        self.onCredentialsSelected = onCredentialsSelected
        self.onCancel = onCancel
    }

    func matchigItems(for items: [PassItem]) -> [PassItem]? {
        Swift.debugPrint("filtering passwords for \(String(describing: serviceIdentifiersStrings))")
        return serviceIdentifiers?.compactMap { serviceIndentifier -> [PassItem]? in
            switch serviceIndentifier.type {
            case .domain:
                return items.filter { passItem in
                    passItem.title?.range(of: serviceIndentifier.identifier) != nil
                }
            case .URL:
                guard let host = URL(string: serviceIndentifier.identifier)?.host else { return nil }
                return items.filter { passItem in
                    if let url = passItem.url?.lowercased(), host.range(of: url) != nil || url.range(of: host) != nil {
                        return true
                    }
                    if let title = passItem.title?.lowercased(), host.range(of: title) != nil || title.range(of: host) != nil {
                        return true
                    }
                    return false
                }
            @unknown default:
                return nil
            }
        }.flatMap { $0 }
    }
}
