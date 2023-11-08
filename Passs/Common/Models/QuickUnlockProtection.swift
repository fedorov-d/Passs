//
//  QuickUnlockProtection.swift
//  Passs
//
//  Created by Dmitry on 24.05.2023.
//

import Foundation

struct QuickUnlockProtection: Codable {
    private(set) var passcode: String?
    private(set) var biometry: Bool

    init?(passcode: String? = nil, biometry: Bool) {
        guard passcode != nil || biometry == true else { return nil }
        self.passcode = passcode
        self.biometry = biometry
    }

    func withPasscode(_ passcode: String?) -> Self? {
        QuickUnlockProtection(passcode: passcode, biometry: biometry)
    }

    func withBiometry(_ biometry: Bool) -> Self? {
        QuickUnlockProtection(passcode: passcode, biometry: biometry)
    }
}

extension QuickUnlockProtection: Equatable {}
