//
//  Application.swift
//  Passs
//
//  Created by Dmitry Fedorov on 02.02.2022.
//

import UIKit

class Application: UIApplication {
    private var timer: Timer?
    private let lockoutInterval = Constants.closeDatabaseTimeInterval

    var onLockout: (() -> Void)?

    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
        if let allTouches = event.allTouches,
           let phase = allTouches.first?.phase,
           phase == .began || phase == .ended {
            resetTimer()
        }
    }

    private func startTimer() {
        timer = Timer(timeInterval: lockoutInterval, repeats: false, block: { [unowned self] timer in
            self.onLockout?()
        })
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        startTimer()
    }

}
