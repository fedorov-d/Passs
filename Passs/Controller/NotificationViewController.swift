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
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentStackView.spacing = 16
        return contentStackView
    }()

    private lazy var iconImage = UIImageView()

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = .preferredFont(forTextStyle: .caption1)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
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
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom).inset(32)
        }
        backgroundView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconImage.image = image
        iconImage.tintColor = .label
        contentStackView.addArrangedSubview(iconImage.embeddedInContainerView(withEdges: .init(top: 10, leading: 16, bottom: 10, trailing: 0)))
        textLabel.text = text
        contentStackView.addArrangedSubview(textLabel.embeddedInContainerView(withEdges: .init(top: 10, leading: 0, bottom: 10, trailing: 16)))
    }

    func show() {
        window = UIWindow()
        window?.backgroundColor = .clear
        window?.isUserInteractionEnabled = false
        window?.isHidden = false
        window?.rootViewController = UIViewController()
        window?.rootViewController?.modalPresentationStyle = .overCurrentContext
        window?.rootViewController?.view.backgroundColor = .clear
        window?.rootViewController?.view.isUserInteractionEnabled = false
        window?.rootViewController?.present(self, animated: true)

        if let timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: 5, repeats: false) { [weak self] timer in
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
