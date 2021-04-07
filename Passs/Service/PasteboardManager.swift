//
//  PasteboardManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import UIKit

protocol PasteboardManager {
    func copy(password: String)
    func dropPasswordIfNeeded(completion: @escaping () -> ())
}

class PasteboardManagerImp: PasteboardManager {
    private var shouldDropPassword = false
    
    func copy(password: String) {
        self.shouldDropPassword = true
        UIPasteboard.general.string = password
        dropPasswordIfNeeded { }
    }
    
    func dropPasswordIfNeeded(completion: @escaping () -> ()) {
        if self.shouldDropPassword {
            Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { _ in
                UIPasteboard.general.string = ""
                completion()
            }
        } else {
            completion()
        }
    }
    
}
