//
//  EnterPasswordViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.04.2021.
//

import UIKit
import SnapKit

class EnterPasswordViewController: UIViewController, UITextFieldDelegate {

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(completion: @escaping (String, Bool) -> ()) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    private let completion: (String, Bool) -> ()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.backgroundColor = .white
        textField.delegate = self
        textField.tintColor = .darkText
        textField.textColor = .darkText
        let font = UIFont.preferredFont(forTextStyle: .callout)
        textField.font = font
        let placeholderTextColor: UIColor
        if #available(iOS 13, *) {
            placeholderTextColor = .label
        } else {
            placeholderTextColor = .lightGray
        }
        textField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.lightGray,
                NSAttributedString.Key.font: font
            ]
        )
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textFieldTextDidChange(_:)), for: .editingChanged)
        return textField
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 3, height: -5)
        view.layer.shadowRadius = 5
        return view
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold, scale: .large)
        let baseImage = UIImage(systemName: "arrow.right.circle.fill", withConfiguration: configuration)
        button.setImage(baseImage?.tinted(with: .systemGreen), for: .normal)
        button.setImage(baseImage?.tinted(with: .lightGray), for: .disabled)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.1)
        return view
    }()

    private lazy var unlockWithTouchIdLabel: UILabel = {
        let label = UILabel()
        label.text = "Unlock with Touch id"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .darkGray
        return label
    }()

    private lazy var unlockWithTouchIdSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isEnabled = false
        return sw
    }()
    
    // MARK: ViewController lifecycle
    
    override func loadView() {
        view = UIView()
        view.isOpaque = false
        view.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupConstraints()
        setupKeyboardObserver()
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissViewController)
        )
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isBeingPresented && !textField.isFirstResponder {
            backgroundView.setNeedsLayout()
            backgroundView.layoutIfNeeded()
            textField.becomeFirstResponder()
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        completion(textField.text ?? "", unlockWithTouchIdSwitch.isOn)
        return true
    }
    
    // MARK: Private calls
    
    private func addSubviews() {
        view.addSubview(backgroundView)
        backgroundView.addSubview(textField)
        backgroundView.addSubview(nextButton)
        backgroundView.addSubview(separatorView)
        backgroundView.addSubview(unlockWithTouchIdLabel)
        backgroundView.addSubview(unlockWithTouchIdSwitch)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.snp.bottom)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(nextButton.snp.leading).offset(-20)
            make.height.equalTo(nextButton)
            make.top.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(textField)
            make.height.width.equalTo(48)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(textField.snp.bottom)
            make.height.equalTo(1)
        }

        unlockWithTouchIdLabel.snp.makeConstraints { make in
            make.leading.equalTo(textField.snp.leading)
            make.centerY.equalTo(separatorView.snp.bottom).offset(24)
        }

        unlockWithTouchIdSwitch.snp.makeConstraints { make in
            make.trailing.equalTo(nextButton.snp.trailing)
            make.centerY.equalTo(unlockWithTouchIdLabel.snp.centerY)
            make.centerY.equalTo(backgroundView.snp.bottom).inset(24)
        }
    }
    
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let keyboardValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                  let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                  let curveInt = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
                  let curve = UIView.AnimationCurve(rawValue: curveInt),
                  let self = self else { return }
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            self.backgroundView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().inset(keyboardScreenEndFrame.height)
            }
            let animator = UIViewPropertyAnimator(
                duration: duration,
                curve: curve) {
                    self.view.backgroundColor = .black.withAlphaComponent(0.15)
                    self.view.layoutIfNeeded()
                }
            animator.startAnimation()
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                  let curveInt = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
                  let curve = UIView.AnimationCurve(rawValue: curveInt),
                  let self = self else { return }
            self.backgroundView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.view.snp.bottom)
            }
            let animator = UIViewPropertyAnimator(
                duration: duration,
                curve: curve) {
                    self.view.backgroundColor = .clear
                    self.view.layoutIfNeeded()
                }
            animator.addCompletion { _ in
                self.dismiss(animated: false, completion: nil)
            }
            animator.startAnimation()
        }

//        NotificationCenter.default.addObserver(
//            forName: UIResponder.keyboardDidHideNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.dismiss(animated: true, completion: nil)
//        }
    }

}

extension EnterPasswordViewController {

    @objc
    private func nextButtonTapped() {
        completion(textField.text ?? "", unlockWithTouchIdSwitch.isOn)
    }

    @objc
    private func textFieldTextDidChange(_ sender: UITextField) {
        nextButton.isEnabled = sender.text?.count ?? 0 > 0
        unlockWithTouchIdSwitch.isEnabled = nextButton.isEnabled
    }

    @objc
    private func dismissViewController() {
        view.endEditing(true)
//        dismiss(animated: true, completion: nil)
    }

}

extension EnterPasswordViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        return !backgroundView.frame.contains(location)
    }

}
