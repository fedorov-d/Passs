//
//  UnlockViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.02.2022.
//

import UIKit
import Combine

final class UnlockViewController: UIViewController {
    private let passDatabaseManager: PassDatabaseManager
    private let databaseURL: URL
    private let localAuthManager: LocalAuthManager
    private let completion: () -> Void

    private var subscriptionSet = Set<AnyCancellable>()

    private let passwordCellId = "passwordCellId"
    private let selectKeyCellId = "selectKeyCellId"
    private let biometryCellId = "biometryCellId"
    private let footerId = "footerId"

    private var unlockData = UnlockData()

    // MARK: init

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(passDatabaseManager: PassDatabaseManager,
         localAuthManager: LocalAuthManager,
         forDatabaseAt url: URL,
         completion: @escaping () -> Void) {
        self.passDatabaseManager = passDatabaseManager
        self.localAuthManager = localAuthManager
        self.databaseURL = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UI components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        }
        tableView.showsVerticalScrollIndicator = false
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
            guard let self else { return }
            self.unlockData.password = newText
            self.navigationItem.rightBarButtonItem?.isEnabled = newText.count > 0
            if newText.count == 0 {
                self.biometryCell?.isOn = false
            }
            self.biometryCell?.isEnabled = newText.count > 0
            self.errorFoorterView.label.isHidden = true
        }
        cell.onReturn = tryUnlock
        return cell
    }()

    private lazy var biometryCell: SwitchCell? = {
        guard localAuthManager.isLocalAuthAvailable() else { return nil }
        let biometryTypeString: String
        switch localAuthManager.biomeryType {
        case .touchID:
            biometryTypeString = "Touch id"
        case .faceID:
            biometryTypeString = "Face id"
        default:
            return nil
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: biometryCellId,
            for: IndexPath(row: 0, section: 2)
        ) as! SwitchCell
        cell.textLabel?.text = "Unlock with \(biometryTypeString)"
        return cell
    }()

    private lazy var selectKeyCell: SelectKeyButtonCell = {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: selectKeyCellId,
            for: IndexPath(row: 0, section: 1)
        ) as! SelectKeyButtonCell
        cell.onButtonTap = { [weak self] in
            self?.openKeyfile()
        }
        cell.title = "Select key"
        return cell
    }()

    private lazy var errorFoorterView: ColoredTableViewHeaderFooterView = {
        let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: footerId
        ) as! ColoredTableViewHeaderFooterView
        footer.label.textColor = .systemRed
        footer.label.text = "Invalid password or key file"
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

    // MARK: - UIViewController lifecycle

    override func loadView() {
        view = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Unlock database"
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
        let localAuthType = localAuthManager.isLocalAuthAvailable() ? localAuthManager.biomeryType : .none
        return localAuthType != .none ? 3 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return passwordCell
        case 1:
            return selectKeyCell
        case 2:
            return biometryCell!
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Enter password"
        case 1:
            return "Key file is not selected"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "Your password will be securely stored in device's keychain"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 {
            return errorFoorterView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.rowHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 5
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 {
            return 0
        }
        return UITableView.automaticDimension
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

    private func tryUnlock() {
        do {
            try passDatabaseManager.unlockDatabase(
                with: databaseURL,
                password:unlockData.password,
                keyFileData: unlockData.keyFileData
            )
            if biometryCell?.isOn ?? false {
                try localAuthManager.saveUnlockData(unlockData, for: databaseURL.lastPathComponent)
            }
            completion()
        } catch _ {
            errorFoorterView.label.isHidden = false
        }
    }

    private func openKeyfile() {
        let documentPicker = UIDocumentPickerViewController.keepassDatabaseKeyfilePicker()
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }

}

extension UnlockViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            try unlockData.setKeyfileURL(url)
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        } catch {
            // TODO: handle error
        }
    }
}

fileprivate extension UnlockViewController {
    enum Constants {
        static let rowHeight: CGFloat = 44
    }
}
