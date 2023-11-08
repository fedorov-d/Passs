//
//  Optional+Extension.swift
//  Passs
//
//  Created by Dmitry on 25.05.2023.
//

import Foundation

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
