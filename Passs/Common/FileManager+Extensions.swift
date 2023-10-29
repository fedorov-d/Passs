//
//  FileManager+Extensions.swift
//  Passs
//
//  Created by Dmitry on 23.10.2023.
//

import Foundation

extension FileManager {
    static var sharedContainerURL: URL? {
        Self.default.containerURL(forSecurityApplicationGroupIdentifier: "group.password.storage")
    }
}
