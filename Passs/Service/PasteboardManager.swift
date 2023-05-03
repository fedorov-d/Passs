//
//  PasteboardManager.swift
//  Passs
//
//  Created by Dmitry Fedorov on 26.03.2021.
//

import UIKit
import Combine

protocol PasteboardManagerDelegate: AnyObject {
    func pasteboardManager(_ pasteboardManager: PasteboardManager, willClearPasteboard progress: ClearProgress)
}

protocol PasteboardManager: AnyObject {
    var delegate: PasteboardManagerDelegate? { get set }
    var needsDropPassword: Bool { get }
    func copy(_: String)
    func clearPasteboard(completion: @escaping () -> Void)
}

final class ClearProgress {
    private(set) @Published var progress: CGFloat = 1.0
    private let timeInterval: TimeInterval
    private let clearDate: Date
    private var timer: Timer?

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
        self.clearDate = Date(timeIntervalSinceNow: timeInterval)
    }

    func start(completion: @escaping () -> Void) {
        let step = timeInterval/0.25
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.progress -= step
            if self.progress == .zero {
                timer?.invalidate()
                completion()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

final class PasteboardManagerImp: PasteboardManager {
    private let clearInterval: TimeInterval
    private var pasteboard: Pasteboard
    private var clearProgress: ClearProgress?

    weak var delegate: PasteboardManagerDelegate?

    init(clearInterval: TimeInterval = Constants.clearPasteboardTimeInterval,
         pasteboard: Pasteboard = UIPasteboard.general) {
        self.clearInterval = clearInterval
        self.pasteboard = pasteboard
    }

    private(set) var needsDropPassword = false
    
    func copy(_ value: String) {
        needsDropPassword = true
        pasteboard.value = value
        clearPasteboard()
    }
    
    func clearPasteboard(completion: @escaping (() -> Void) = {}) {
        guard needsDropPassword else {
            completion()
            return
        }
        clearProgress = ClearProgress(timeInterval: clearInterval)
        clearProgress?.start { [weak self] in
            self.?pasteboard.value = ""
            completion()
        }
    }
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
