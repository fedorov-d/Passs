//
//  EnterPasswordViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 08.04.2021.
//

import UIKit
import SnapKit

class EnterPasswordViewController: UIViewController, UITextFieldDelegate {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
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
        textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
        
        textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(44)
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
