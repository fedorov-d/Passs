//
//  ProgressNavigationBar.swift
//  Passs
//
//  Created by Dmitry Fedorov on 03.05.2023.
//

import UIKit
import Combine

final class ProgressNavigationBar: UINavigationBar {
    private var cancellables = Set<AnyCancellable>()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.tintColor = .systemBlue
        progressView.progress = 0
        return progressView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(progressView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.frame = CGRect(x: 0, y: bounds.maxY - progressView.bounds.height,
                                    width: bounds.width, height: progressView.bounds.height)
    }
}

extension ProgressNavigationBar: PasteboardManagerDelegate {
    func pasteboardManager(_ pasteboardManager: PasteboardManager, willClearPasteboard progress: ClearProgress) {
        progress.$progress.sink { [weak self] in
            self?.progressView.progress = Float($0)
        }
        .store(in: &cancellables)
    }
}
