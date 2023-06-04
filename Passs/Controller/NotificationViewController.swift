//
//  NotificationViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 02.05.2023.
//

import UIKit
import Combine

final class NotificationViewController: UIViewController {
    private var window: UIWindow?
    private let image: UIImage
    private let text: String
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(image: UIImage, text: String) {
        self.image = image
        self.text = text
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .currentContext
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .tertiarySystemBackground
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.cornerCurve = .continuous
        return backgroundView
    }()

    private lazy var contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .horizontal
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.spacing = 16
        return contentStackView
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = image
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label
        return iconImageView
    }()

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = .preferredFont(forTextStyle: .caption1)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
        textLabel.text = text
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return textLabel
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(view.readableContentGuide.snp.width)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }

        backgroundView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStackView.addArrangedSubview(
            iconImageView.embedded(edges: .init(top: 10, leading: 16, bottom: 10, trailing: 0))
        )
        contentStackView.addArrangedSubview(
            textLabel.embedded(edges: .init(top: 10, leading: 0, bottom: 10, trailing: 16))
        )
    }

    func show(for timeInterval: TimeInterval = 4) {
        let window = UIWindow()
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        window.isHidden = false
        window.rootViewController = UIViewController()
        window.rootViewController?.modalPresentationStyle = .overCurrentContext
        window.rootViewController?.view.backgroundColor = .clear
        window.rootViewController?.view.isUserInteractionEnabled = false
        window.rootViewController?.present(self, animated: true)
        self.window = window

        if let timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: timeInterval, repeats: false) { [weak self] timer in
            self?.dismiss()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func dismiss() {
        window?.rootViewController?.dismiss(animated: true, completion: {
            self.window?.rootViewController = nil
            self.window?.isHidden = false
        })
    }
}
