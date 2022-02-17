//
//  UnlockViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.02.2022.
//

import UIKit
import Combine

class UnlockViewController: UIViewController {

    private let passDatabaseManager: PassDatabaseManager
    private let database: StoredDatabase
    private let completion: (String, Bool) -> Void

    private var subscriptionSet = Set<AnyCancellable>()

    private let passwordCellId = "passwordCellId"
    private let selectKeyCellId = "selectKeyCellId"
    private let biometryCellId = "biometryCellId"
    private let footerId = "footerId"

    // MARK: init

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
    }


    // MARK: - UI components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: passwordCellId)
        tableView.register(SwitchCell.self, forCellReuseIdentifier: biometryCellId)
        tableView.register(ColoredTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: footerId)
        tableView.register(SelectKeyButtonCell.self, forCellReuseIdentifier: selectKeyCellId)
        return tableView
    }()

    private lazy var passwordCell: TextFieldCell = {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: passwordCellId,
            for: IndexPath(row: 0, section: 0)
        ) as! TextFieldCell
        cell.onTextChanged = { [weak self] newText in
            guard let self = self else { return }
            self.navigationItem.rightBarButtonItem?.isEnabled = newText.count > 0
            if newText.count == 0 {
                self.biometryCell.isOn = false
            }
            self.biometryCell.isEnabled = newText.count > 0
            self.errorFoorterView.label.isHidden = true
        }
        cell.onReturn = tryUnlock
        return cell
    }()

    private lazy var biometryCell: SwitchCell = {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: biometryCellId,
            for: IndexPath(row: 0, section: 1)
        ) as! SwitchCell
        cell.textLabel?.text = "Unlock with biometry"
        return cell
    }()

    private lazy var selectKeyCell: SelectKeyButtonCell = {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: selectKeyCellId,
            for: IndexPath(row: 0, section: 0)
        ) as! SelectKeyButtonCell
        cell.onButtonTap = { [weak self] in
            // TODO: select key file
        }
        return cell
    }()

    private lazy var errorFoorterView: ColoredTableViewHeaderFooterView = {
        let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: footerId
        ) as! ColoredTableViewHeaderFooterView
        footer.label.textColor = .systemRed
        footer.label.text = "Invalid password"
        footer.label.isHidden = true
        return footer
    }()

    private lazy var cancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(dismissViewController)
    )

    private lazy var unlockButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Unlock",
            style: .done,
            target: nil,
            action: #selector(unlockTapped(_:))
        )
        button.isEnabled = false
        return button
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let result = UISegmentedControl(items: ["Password", "Key file"])
        result.selectedSegmentIndex = 0
        result.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        return result
    }()

    // MARK: - viewController lifecycle

    override func loadView() {
        view = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .secondarySystemBackground
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }
        navigationItem.titleView = segmentedControl
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = unlockButton
        setupKeyboardObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = passwordCell.becomeFirstResponder()
    }

}

// MARK: - keyboard events
extension UnlockViewController {

    private func setupKeyboardObserver() {
        keyboardWillChangeFrameNotificationPublisher()
            .sink { [weak self] keyboardParams in
                self?.adjustTableInsets(with: keyboardParams.frameEnd)
            }
            .store(in: &subscriptionSet)
    }

    private func adjustTableInsets(with keyboardFrame: CGRect) {
        var inset = tableView.contentInset
        inset.bottom = keyboardFrame.height
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }

}

// MARK: - tableView
extension UnlockViewController: UITableViewDataSource, UITableViewDelegate  {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if segmentedControl.selectedSegmentIndex == 0 {
                return passwordCell
            } else {
                return selectKeyCell
            }
        case 1:
            return biometryCell
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if segmentedControl.selectedSegmentIndex == 0 {
                return "Enter password"
            } else {
                return "Key file is not selected"
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "Your password will be securely stored in device's keychain"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            return errorFoorterView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
}

// MARK: - target/action
extension UnlockViewController {

    @objc
    private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func unlockTapped(_ sender: AnyObject) {
        tryUnlock()
    }

    @objc
    private func segmentValueChanged(_ sender: UISegmentedControl) {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        if (sender.selectedSegmentIndex == 0) {
            _ = passwordCell.becomeFirstResponder()
        }
    }

    private func tryUnlock() {
        let password = passwordCell.text
        do {
            try passDatabaseManager.load(databaseURL: self.database.url, password:password)
            completion(password, biometryCell.isOn)
        } catch _ {
            errorFoorterView.label.isHidden = false
        }
    }

}
