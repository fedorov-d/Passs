//
//  CredentialsSelectionManager.swift
//  Passs
//
//  Created by Dmitry on 01.12.2022.
//

import Foundation

protocol CredentialsSelectionManager: AnyObject {
    var onCredentialsSelected: ((PassItem) -> Void)? { get set }
}

final class CredentialsSelectionManagerImp: CredentialsSelectionManager {
    var onCredentialsSelected: ((PassItem) -> Void)?
}
