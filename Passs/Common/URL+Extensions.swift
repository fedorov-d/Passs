//
//  URL+Extensions.swift
//  Passs
//
//  Created by Dmitry on 23.10.2023.
//

import Foundation

extension URL {
    func kp_appendingPathComponent(_ pathComponent: String) -> URL {
        if #available(iOS 16.0, *) {
            return appending(path: pathComponent)
        } else {
            return appendingPathComponent(pathComponent)
        }
    }
}
