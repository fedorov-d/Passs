//
//  ProtectionStorage.swift
//  Passs
//
//  Created by Dmitry on 03.10.2023.
//

import Foundation

protocol ProtectionStorage: AnyObject {
    func protection(for database: String) -> QuickUnlockProtection?
    func setProtection(_ protection: QuickUnlockProtection, for database: String) throws
    func deleteProtection(for database: String) throws
}
