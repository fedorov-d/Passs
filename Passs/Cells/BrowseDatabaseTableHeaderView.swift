//
//  BrowseDatabaseTableHeaderView.swift
//  Passs
//
//  Created by Dmitry on 30.04.2023.
//

import UIKit

final class BrowseDatabaseTableHeaderView: UIView {
    var buttonAction: (() -> Void)?

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Browse database", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonTapped() {
        buttonAction?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds.insetBy(dx: 28, dy: 10)
    }
}
