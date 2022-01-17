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
    
    init(completion: @escaping (String) -> ()) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    private let completion: (String) -> ()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.textAlignment = .center
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.placeholder = "Password"
        textField.delegate = self
        textField.tintColor = .black
        textField.textColor = .black
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textFieldTextDidChange(_:)), for: .editingChanged)
        return textField
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 14.0
        view.layer.masksToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 3, height: -5)
        view.layer.shadowRadius = 5
        return view
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        let baseImage = UIImage(named: "arrow.right.circle.fill")
        button.setBackgroundImage(baseImage?.tinted(with: .black), for: .normal)
        button.setBackgroundImage(baseImage?.tinted(with: .lightGray), for: .disabled)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    // MARK: ViewController lifecycle
    
    override func loadView() {
        view = UIView()
        view.isOpaque = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupConstraints()
        setupKeyboardObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        textField.becomeFirstResponder()
        super.viewDidAppear(animated)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        completion(textField.text ?? "")
        return true
    }
    
    // MARK: Private calls
    
    private func addSubviews() {
        view.addSubview(backgroundView)
        backgroundView.addSubview(textField)
        backgroundView.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
        
        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(nextButton.snp.leading).offset(-20)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(40)
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.height.centerY.equalTo(textField)
            make.width.equalTo(textField.snp.height)
        }
    }
    
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] note in
            guard let keyboardValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            
            self?.backgroundView.snp.updateConstraints { make in
                make.height.equalTo(keyboardScreenEndFrame.height + 84)
            }
            UIView.animate(withDuration: 0.3) {
                self?.backgroundView.layoutIfNeeded()
            }
        }
    }

}

extension EnterPasswordViewController {

    @objc
    private func nextButtonTapped() {
        completion(textField.text ?? "")
    }

    @objc
    private func textFieldTextDidChange(_ sender: UITextField) {
        nextButton.isEnabled = sender.text?.count ?? 0 > 0
    }

}
