//
//  PasteboardManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import UIKit

protocol PasteboardManager {
    func copy(_: String)
    var needsDropPassword: Bool { get }
    func dropPassword(completion: @escaping () -> Void)
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

final class PasteboardManagerImp: PasteboardManager {

    private let clearInterval: TimeInterval
    private var pasteboard: Pasteboard
    private var timer: Timer?

    private let dropPasswordInterval: TimeInterval = 20

    init(
        clearInterval: TimeInterval = Constants.clearPasteboardTimeInterval,
        pasteboard: Pasteboard = UIPasteboard.general
    ) {
        self.clearInterval = clearInterval
        self.pasteboard = pasteboard
    }

    private(set) var needsDropPassword = false
    
    func copy(_ value: String) {
        self.needsDropPassword = true
        pasteboard.value = value
        dropPassword()
    }
    
    func dropPassword(completion: @escaping (() -> Void) = {}) {
        guard self.needsDropPassword else {
            completion()
            return
        }
        timer?.invalidate()
        timer = Timer(timeInterval: dropPasswordInterval, repeats: false) { [weak self] _ in
            completion()
            guard let self = self else { return }
            self.pasteboard.value = ""
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
}
