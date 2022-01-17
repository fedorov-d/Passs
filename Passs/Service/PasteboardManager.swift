//
//  PasteboardManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import UIKit

protocol PasteboardManager {
    func copy(password: String)
    var needsDropPassword: Bool { get }
    func dropPassword(completion: @escaping () -> ())
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

    private(set) var needsDropPassword = false
    
    func copy(password: String) {
        self.needsDropPassword = true
        pasteboard.value = password
        dropPassword()
    }
    
    func dropPassword(completion: @escaping (() -> Void) = {}) {
        guard self.needsDropPassword else {
            completion()
            return
        }
        let timer = Timer(timeInterval: 20, repeats: false) { [weak self] _ in
            completion()
            guard let self = self else { return }
            self.pasteboard.value = nil
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
}
