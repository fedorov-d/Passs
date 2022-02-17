//
//  EnterPasswordViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.04.2021.
//

import UIKit
import SnapKit
import Combine

class EnterPasswordViewController: UIViewController, UITextFieldDelegate {

    private let passDatabaseManager: PassDatabaseManager
    private let database: StoredDatabase

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(
        passDatabaseManager: PassDatabaseManager,
        database: StoredDatabase,
        completion: @escaping (String, Bool) -> Void
    ) {
        self.passDatabaseManager = passDatabaseManager
        self.database = database
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    private let completion: (String, Bool) -> Void
    private var subscriptionSet = Set<AnyCancellable>()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.textAlignment = .center
        textField.delegate = self
        let font = UIFont.preferredFont(forTextStyle: .callout)
        textField.font = font
        let placeholderTextColor: UIColor
        placeholderTextColor = .label
        textField.borderStyle = .roundedRect
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
        view.backgroundColor = .tertiarySystemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 3, height: -5)
        view.layer.shadowRadius = 5
        return view
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Unlock", for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.secondaryLabel, for: .disabled)
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()

    private lazy var unlockWithTouchIdLabel: UILabel = {
        let label = UILabel()
        label.text = "Unlock with Touch id"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var errordLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .systemRed
        label.isHidden = true
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
        nextButtonTapped()
        return true
    }
    
    // MARK: Private calls
    
    private func addSubviews() {
        view.addSubview(backgroundView)
        backgroundView.addSubview(stackView)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(unlockWithTouchIdLabel)
        stackView.addArrangedSubview(unlockWithTouchIdSwitch)
        stackView.addArrangedSubview(errordLabel)
        stackView.addArrangedSubview(nextButton)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.snp.bottom)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints { make in
//            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
//            make.top.equalToSuperview().offset(20)
        }
//
//        unlockWithTouchIdLabel.snp.makeConstraints { make in
//            make.leading.equalTo(textField.snp.leading)
//            make.centerY.equalTo(textField.snp.bottom).offset(24)
//        }
//
//        unlockWithTouchIdSwitch.snp.makeConstraints { make in
//            make.trailing.equalToSuperview().offset(-20)
//            make.centerY.equalTo(unlockWithTouchIdLabel.snp.centerY)
//        }
//
        nextButton.snp.makeConstraints { make in
//            make.leading.trailing.bottom.equalToSuperview().inset(20)
//            make.top.equalTo(unlockWithTouchIdSwitch.snp.bottom).offset(15)
            make.height.equalTo(48)
        }
    }
    
    private func setupKeyboardObserver() {

        keyboardWillShowPublisher()
            .sink { [weak self] keyboardParams in
                guard let self = self else { return }
                self.backgroundView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview().inset(keyboardParams.frameEnd.height)
                }
                let animator = UIViewPropertyAnimator(
                    duration: keyboardParams.animationDuration,
                    curve: keyboardParams.animationCurve
                ) {
                        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
                        self.view.layoutIfNeeded()
                    }
                animator.startAnimation()
            }
            .store(in: &subscriptionSet)

        keyboardWillHidePublisher()
            .sink { [weak self] keyboardParams in
                guard let self = self else { return }
                self.backgroundView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.view.snp.bottom)
                }
                let animator = UIViewPropertyAnimator(
                    duration: keyboardParams.animationDuration,
                    curve: keyboardParams.animationCurve
                ) {
                        self.view.backgroundColor = .clear
                        self.view.layoutIfNeeded()
                    }
                animator.addCompletion { _ in
                    self.dismiss(animated: false, completion: nil)
                }
                animator.startAnimation()
            }
            .store(in: &subscriptionSet)
    }

}

extension EnterPasswordViewController {

    @objc
    private func nextButtonTapped() {
        let password = textField.text ?? ""
        do {
            try passDatabaseManager.load(databaseURL: self.database.url, password:password)
            completion(password, unlockWithTouchIdSwitch.isOn)
        } catch _ {
            errordLabel.text = "Invalid password"
            UIView.animate(withDuration: 0.3) {
                self.errordLabel.isHidden = false
            }
        }
    }

    @objc
    private func textFieldTextDidChange(_ sender: UITextField) {
        nextButton.isEnabled = sender.text?.count ?? 0 > 0
        if sender.text?.count ?? 0 == 0 {
            unlockWithTouchIdSwitch.isOn = false
        }
        if errordLabel.isHidden == false {
            UIView.animate(withDuration: 0.3) {
                self.errordLabel.isHidden = true
            }
        }
        unlockWithTouchIdSwitch.isEnabled = nextButton.isEnabled
    }

    @objc
    private func dismissViewController() {
        view.endEditing(true)
    }

}

extension EnterPasswordViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        return !backgroundView.frame.contains(location)
    }

}
