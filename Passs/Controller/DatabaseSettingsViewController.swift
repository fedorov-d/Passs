//
//  DatabaseSettingsViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 23.05.2023.
//

import SwiftUI

final class DatabaseSettingsViewController: UIViewController {
    private let quickUnlockManager: QuickUnlockManager
    private var initialProtection: QuickUnlockProtection?
    private var currentProtection: QuickUnlockProtection? {
        didSet {
            saveButton.isEnabled = currentProtection != initialProtection
            biometryCell.isOn = currentProtection?.biometry ?? false
        }
    }
    private let database: String

    private lazy var dataSource = makeDataSource()

    init(quickUnlockManager: QuickUnlockManager, database: String) {
        self.quickUnlockManager = quickUnlockManager
        self.database = database
        self.currentProtection = quickUnlockManager.protection(for: database)
        self.initialProtection = currentProtection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var cancelButton = makeCancelBarButtonItem()

    private lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        button.isEnabled = false
        return button
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        }
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    private lazy var biometryCell: SwitchCell = {
        let isLocalAuthAvailable = quickUnlockManager.isLocalAuthAvailable()
        var text = ""

        switch (isLocalAuthAvailable, quickUnlockManager.biomeryType) {
        case (true, .touchID):
            text = "Use Touch id"
        case (true, .faceID):
            text = "Use Face id"
        default:
            text = "Biometric auth is disabled"
        }
        let cell = SwitchCell(style: .default, reuseIdentifier: String())
        cell.onSwitchValueChanged = { [weak self] biometry in
            guard let self else { return }
            guard var currentProtection = self.currentProtection else {
                if biometry {
                    self.currentProtection = QuickUnlockProtection(biometry: true)
                }
                return
            }
            if !biometry && currentProtection.passcode.isNilOrEmpty {
                self.currentProtection = nil
            } else {
                self.currentProtection = currentProtection.withBiometry(biometry)
            }
        }
        cell.isOn = currentProtection?.biometry ?? false
        cell.isEnabled = true
        cell.textLabel?.text = text
        return cell
    }()

    private lazy var passcodeCell: SwitchCell = {
        let cell = SwitchCell(style: .default, reuseIdentifier: String())
        cell.onSwitchValueChanged = { [weak self] isOn in
            guard let self else { return }
            if isOn {
                let passcodeView = PasscodeView(scenario: .init(steps: [
                    .init(type: .create),
                    .init(type: .repeat)
                ], onComplete: { [weak self] passcode in
                    guard let self else { return }
                    if let currentProtection {
                        self.currentProtection = currentProtection.withPasscode(passcode)
                    } else {
                        self.currentProtection = QuickUnlockProtection(passcode: passcode, biometry: false)
                    }
                    self.navigationController?.popViewController(animated: true)
                }))
                let controller = UIHostingController(rootView: passcodeView)
                self.navigationController?.pushViewController(controller, animated: true)
            } else {
                self.currentProtection = self.currentProtection?.withPasscode(nil)
            }
        }
        cell.isOn = currentProtection?.passcode != nil
        cell.isEnabled = true
        cell.textLabel?.text = "Passcode"
        return cell
    }()
}

extension DatabaseSettingsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = dataSource
        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passcodeCell.isOn = currentProtection?.passcode != nil
    }
}

extension DatabaseSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension DatabaseSettingsViewController {
    private func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Element>()
        let section: Section = .main
        snapshot.appendSections([section])
        snapshot.appendItems([.biometricAuth, .passcode],
                             toSection: section)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    @objc
    private func dismissViewController() {
        dismiss(animated: true)
    }

    @objc
    private func saveTapped() {
        do {
            if let currentProtection {
                try quickUnlockManager.setProtection(currentProtection, for: database)
            } else {
                try quickUnlockManager.deleteProtection(for: database)
            }
            dismiss(animated: true)
        } catch {
            Swift.debugPrint(error)
            // TODO: display error alert
        }
    }
}

private extension DatabaseSettingsViewController {
    enum Section: String {
        case main
    }

    enum Element: String {
        case biometricAuth, passcode
    }

    final class DiffableDataSource: UITableViewDiffableDataSource<Section, Element> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let section = snapshot().sectionIdentifiers[section]
            switch section {
            case .main:
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
                case .biometricAuth:
                    return self.biometryCell
                case .passcode:
                    return self.passcodeCell
                }
            }
        )
    }
}
