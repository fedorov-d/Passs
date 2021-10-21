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

protocol Pasteboard: AnyObject {
    var value: String? { get set }
}

extension UIPasteboard: Pasteboard {
    var value: String? {
        get {
            return string
        }
        set {
            string = newValue
        }
    }
}

class PasteboardManagerImp: PasteboardManager {

    private let clearInterval: TimeInterval
    private var pasteboard: Pasteboard

    init(
        clearInterval: TimeInterval = Constants.clearPasteboardTimeInterval,
        pasteboard: Pasteboard = UIPasteboard.general
    ) {
        self.clearInterval = clearInterval
        self.pasteboard = pasteboard
    }

    private var needsDropPassword = false
    
    func copy(password: String) {
        self.needsDropPassword = true
        pasteboard.value = password
        dropPasswordIfNeeded { }
    }
    
    func dropPasswordIfNeeded(completion: @escaping () -> ()) {
        if self.needsDropPassword {
            let timer = Timer(timeInterval: 20, repeats: false) { [weak self] _ in
                self?.pasteboard.value = nil
                completion()
            }
            RunLoop.main.add(timer, forMode: .common)
        } else {
            completion()
        }
    }
    
}
