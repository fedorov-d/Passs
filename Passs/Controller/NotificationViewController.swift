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

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom).inset(16)
            make.height.equalTo(54)
        }
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
