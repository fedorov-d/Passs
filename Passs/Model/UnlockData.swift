//
//  UnlockData.swift
//  Passs
//
//  Created by Dmitry Fedorov on 18.02.2022.
//

import Foundation

struct UnlockData {
    var password: String?

    private(set) var keyFileData: Data?
    private(set) var keyFileName: String?

    mutating func setKeyfileURL(_ url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            Swift.debugPrint("Cannot access security-scoped URL: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        keyFileName = url.lastPathComponent
        keyFileData = try Data(contentsOf: url)
    }
}

extension UnlockData: Codable {
}
