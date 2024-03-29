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
        progressView.tintColor = .keepCyan.withAlphaComponent(0.6)
        progressView.progress = 0
        progressView.isAccessibilityElement = false
        return progressView
    }()

    private lazy var progressViewContainer: UIView = {
        let progressViewContainer = UIView()
        progressViewContainer.clipsToBounds = true
        return progressViewContainer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(progressView.embedded(in: progressViewContainer, edges: .zero))
        updateApperance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressViewContainer.frame = CGRect(x: 0, y: bounds.maxY - 0.5,
                                             width: bounds.width, height: 0.5)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateApperance()
    }
}

private extension ProgressNavigationBar {
    func updateApperance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = 
            .systemBackground
        standardAppearance = appearance
        compactAppearance = appearance
        appearance.shadowColor = nil
        scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            compactScrollEdgeAppearance = appearance
        }
    }
}

extension ProgressNavigationBar: PasteboardManagerDelegate {
    func pasteboardManager(_ pasteboardManager: PasteboardManager, willClearPasteboard progress: ClearProgress) {
        progressView.progress = 1.0
        progress.$progress.sink { [weak self] in
            self?.progressView.setProgress(Float($0), animated: true)
        }
        .store(in: &cancellables)
    }
}
