//
//  UIViewController+Extensions.swift
//  Passs
//
//  Created by Dmitry Fedorov on 04.02.2022.
//

import UIKit
import Combine

extension UIViewController {
    struct KeyboardParams {
        let frameEnd: CGRect
        let frameBegin: CGRect
        let animationDuration: TimeInterval
        let animationCurve: UIView.AnimationCurve
        let isLocal: Bool

        init?(userInfo: [AnyHashable: Any]?) {
            guard let frameEnd = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                  let frameBegin = userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue,
                  let animationDuration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                  let curveInt = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
                  let animationCurve = UIView.AnimationCurve(rawValue: curveInt),
                  let isLocal = userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool else { return nil }
            self.frameEnd = frameEnd.cgRectValue
            self.frameBegin = frameBegin.cgRectValue
            self.animationDuration = animationDuration
            self.animationCurve = animationCurve
            self.isLocal = isLocal
        }
    }

    func keyboardWillShowPublisher() -> AnyPublisher<KeyboardParams, Never> {
        keyboardPublisher(for: UIResponder.keyboardWillShowNotification)
    }

    func keyboardWillHidePublisher() -> AnyPublisher<KeyboardParams, Never> {
        keyboardPublisher(for: UIResponder.keyboardWillHideNotification)
    }

    func keyboardWillChangeFrameNotificationPublisher() -> AnyPublisher<KeyboardParams, Never> {
        keyboardPublisher(for: UIResponder.keyboardWillChangeFrameNotification)
    }

    private func keyboardPublisher(for name: Notification.Name) -> AnyPublisher<KeyboardParams, Never> {
        NotificationCenter.default.publisher(for: name, object: nil)
            .compactMap { note in
                return KeyboardParams(userInfo: note.userInfo)
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func applicationDidBecomeActivePublisher() -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func applicationDidEnterBackground() -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: RunLoop.main)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func applicationWillResignActivePublisher() -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: RunLoop.main)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func setupKeyboardAvoidance(for scrollView: UIScrollView, subscriptionSet: inout Set<AnyCancellable>) {
        keyboardWillShowPublisher()
            .sink { [weak self] params in
                guard let self else { return }
                var currentInset = scrollView.contentInset
                currentInset.bottom = params.frameEnd.height - self.view.safeAreaInsets.bottom
                scrollView.contentInset = currentInset
                scrollView.scrollIndicatorInsets = currentInset
            }
            .store(in: &subscriptionSet)

        keyboardWillHidePublisher()
            .sink { params in
                var currentInset = scrollView.contentInset
                currentInset.bottom = 0
                scrollView.contentInset = currentInset
                scrollView.scrollIndicatorInsets = currentInset
            }
            .store(in: &subscriptionSet)
    }
}

extension UIViewController {
    func embed(in parentViewController: UIViewController) {
        willMove(toParent: parentViewController)
        parentViewController.addChild(self)
        parentViewController.view.addSubview(view)
        didMove(toParent: parentViewController)
    }
}

extension UIViewController {
    func setCancelNavigationItemIfNeeded(with credentialSelectionManager: CredentialsSelectionManager?) {
        guard let credentialSelectionManager else { return }
        setCancelNavigationItem {
            credentialSelectionManager.onCancel()
        }
    }

    fileprivate func setCancelNavigationItem(with action: @escaping () -> Void) {
        let barButtonItem = BarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        barButtonItem.configure(with: action)
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
}
