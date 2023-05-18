//
//  UnlockViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.02.2022.
//

import UIKit
import Combine
import SwiftUI

final class UnlockViewController: UIViewController {
    private let passDatabaseManager: PassDatabaseManager
    private let databaseURL: URL
    private let localAuthManager: LocalAuthManager
    private let completion: () -> Void

    private var cancellables = Set<AnyCancellable>()

    private let passwordCellId = "passwordCellId"
    private let selectKeyCellId = "selectKeyCellId"
    private let biometryCellId = "biometryCellId"
    private let passcodeCellId = "passcodeCellId"
    private let footerId = "footerId"

    private var unlockData = UnlockData()

    private lazy var dataSource = makeDataSource()

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
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        }
        tableView.rowHeight = Constants.rowHeight
        tableView.showsVerticalScrollIndicator = false
        tableView.register(GenericContentTableViewCell<UITextField>.self, forCellReuseIdentifier: passwordCellId)
        tableView.register(SwitchCell.self, forCellReuseIdentifier: biometryCellId)
        tableView.register(ColoredTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: footerId)
        tableView.register(SelectKeyButtonCell.self, forCellReuseIdentifier: selectKeyCellId)
        tableView.register(Value1TableViewCell.self, forCellReuseIdentifier: passcodeCellId)
        return tableView
    }()

    private lazy var passwordCell: GenericContentTableViewCell<UITextField> = {
        let cell = GenericContentTableViewCell<UITextField>(style: .default, reuseIdentifier: passwordCellId)
        cell.customContentInset = .init(top: 2, leading: 16, bottom: 2, trailing: 16)
        cell.selectionStyle = .none
        let textField = cell.customContentView
        textField.delegate = self
        textField.isSecureTextEntry = true
        textField.placeholder = "Password"
        textField.font = UIFont.preferredFont(forTextStyle: .callout)
        textField.borderStyle = .none
        textField.returnKeyType = .continue
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(passwordTextDidChange(_:)), for: .editingChanged)
        return cell
    }()

    private lazy var biometryCell: SwitchCell = {
        let text: String
        switch localAuthManager.biomeryType {
        case .touchID:
            text = "Use Touch id"
        case .faceID:
            text = "Use Face id"
        default:
            text = "Biometric auth is disabled"
        }
        let cell = SwitchCell(style: .default, reuseIdentifier: biometryCellId)
        cell.textLabel?.text = text
        return cell
    }()

    private lazy var selectKeyCell: SelectKeyButtonCell = {
        let cell = SelectKeyButtonCell(style: .default, reuseIdentifier: selectKeyCellId)
        cell.onButtonTap = { [weak self] in
            self?.openKeyfile()
        }
        cell.title = "Select key"
        return cell
    }()

    private lazy var passcodeCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: passcodeCellId)
        cell.textLabel?.text = "Passcode"
        cell.detailTextLabel?.text = "Off"
        cell.accessoryType = .disclosureIndicator
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

    private lazy var clearKeyButton: UIButton = {
        let button = UIButton(type: .close)
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.unlockData.resetKeyfile()
            self.selectKeyCell.title = "Select key"
            self.selectKeyCell.accessoryView = nil
        }, for: .touchUpInside)
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

        tableView.dataSource = dataSource
        updateDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = passwordCell.customContentView.becomeFirstResponder()
    }

    private func updateDataSource(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Element>()
        let unlockDataInputSection: Section = .unlockDataInput
        snapshot.appendSections([unlockDataInputSection])
        snapshot.appendItems([.password, .keyFile], toSection: unlockDataInputSection)

        let saveUnlockDataSection: Section = .saveUnlockData
        snapshot.appendSections([saveUnlockDataSection])
        snapshot.appendItems([.faceID, .passcode],
                             toSection: saveUnlockDataSection)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - keyboard events
extension UnlockViewController {
    private func setupKeyboardObserver() {
        keyboardWillChangeFrameNotificationPublisher()
            .sink { [weak self] keyboardParams in
                self?.adjustTableInsets(with: keyboardParams.frameEnd)
            }
            .store(in: &cancellables)
    }

    private func adjustTableInsets(with keyboardFrame: CGRect) {
        var inset = tableView.contentInset
        inset.bottom = keyboardFrame.height
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
}

// MARK: - tableView
extension UnlockViewController: UITableViewDelegate  {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        if section == .saveUnlockData {
            return errorFoorterView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        if section == .unlockDataInput {
            return 5
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
        switch element {
        case .passcode:
            let passcodeView = PasscodeView(scenario: .init(steps: [
                .init(type: .create),
                .init(type: .repeat)
            ], onDismiss: {

            }))
            let controller = UIHostingController(rootView: passcodeView)
            navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
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
    private func passwordTextDidChange(_ sender: UITextField) {
        let newText = sender.text ?? ""
        self.unlockData.password = newText
        self.navigationItem.rightBarButtonItem?.isEnabled = newText.count > 0
        if newText.count == 0 {
            self.biometryCell.isOn = false
        }
        self.biometryCell.isEnabled = newText.count > 0
        self.errorFoorterView.label.isHidden = true
    }

    private func tryUnlock() {
        do {
            try passDatabaseManager.unlockDatabase(
                with: databaseURL,
                password:unlockData.password,
                keyFileData: unlockData.keyFileData
            )
            if biometryCell.isOn {
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
            selectKeyCell.title = unlockData.keyFileName
            selectKeyCell.accessoryView = clearKeyButton
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

extension UnlockViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tryUnlock()
        return true
    }
}

private extension UnlockViewController {
    enum Section: String {
        case unlockDataInput
        case saveUnlockData
    }

    enum Element: String {
        case password, keyFile, faceID, passcode
    }

    final class DiffableDataSource: UITableViewDiffableDataSource<Section, Element> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let section = snapshot().sectionIdentifiers[section]
            switch section {
            case .saveUnlockData:
                return "Quick unlock"
            default:
                return nil
            }
        }
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, Element> {
        return DiffableDataSource(
            tableView: tableView,
            cellProvider: { [weak self]  tableView, indexPath, element in
                guard let self else { return UITableViewCell() }
                switch element {
                case .password:
                    return passwordCell
                case .keyFile:
                    return selectKeyCell
                case .faceID:
                    return biometryCell
                case .passcode:
                    return passcodeCell
                }
            }
        )
    }
}
