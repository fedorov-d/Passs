//
//  CredentialsSelectionManager.swift
//  Passs
//
//  Created by Dmitry on 01.12.2022.
//

import Foundation

protocol CredentialsSelectionManager: AnyObject {
    var onCredentialsSelected: ((PassItem) -> Void) { get }
    var onCancel: (() -> Void) { get }
}

final class CredentialsSelectionManagerImp: CredentialsSelectionManager {
    let onCredentialsSelected: (PassItem) -> Void
    let onCancel: () -> Void

    init(onCredentialsSelected: @escaping (PassItem) -> Void,
         onCancel: @escaping () -> Void) {
        self.onCredentialsSelected = onCredentialsSelected
        self.onCancel = onCancel
    }
}
