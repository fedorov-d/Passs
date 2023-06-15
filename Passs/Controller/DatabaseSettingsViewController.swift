//
//  DatabaseSettingsViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 23.05.2023.
//

import SwiftUI


final class DatabaseSettingsViewController: UIViewController {
    struct SettingsState {
        private let initialProtection: QuickUnlockProtection?
        private(set) var currentProtection: QuickUnlockProtection?
        private let initialOpenOnStartup: Bool
        private(set) var currentOpenOnStartup: Bool

        init(protection: QuickUnlockProtection?, openOnStartup: Bool) {
            self.initialProtection = protection
            self.currentProtection = protection
            self.initialOpenOnStartup = openOnStartup
            self.currentOpenOnStartup = openOnStartup
        }

        var hasChanges: Bool {
            openOnStartupChanged || protectionChanged
        }

        var protectionChanged: Bool {
            currentProtection != initialProtection
        }

        var openOnStartupChanged: Bool {
            initialOpenOnStartup != currentOpenOnStartup
        }

        var hasBiometry: Bool {
            currentProtection?.biometry == true
        }

        var hasPasscode: Bool {
            currentProtection?.passcode != nil
        }

        mutating func setBiometryOn(_ isOn: Bool) {
            if let currentProtection {
                self.currentProtection = currentProtection.withBiometry(isOn)
            } else {
                self.currentProtection = QuickUnlockProtection(biometry: isOn)
            }
        }

        mutating func setPasscode(_ passcode: String?) {
            if let currentProtection {
                self.currentProtection = currentProtection.withPasscode(passcode)
            } else {
                self.currentProtection = QuickUnlockProtection(passcode: passcode, biometry: false)
            }
        }

        mutating func setOpenOnStartup(_ open: Bool) {
            currentOpenOnStartup = open
        }
    }
    private let quickUnlockManager: QuickUnlockManager
    private let settingsManager: SettingsManager
    private var settingsState: SettingsState {
        didSet {
            saveButton.isEnabled = settingsState.hasChanges
            biometryCell.isOn = settingsState.hasBiometry
        }
    }
    private let database: URL

    private lazy var dataSource = makeDataSource()

    init(quickUnlockManager: QuickUnlockManager, settingsManager: SettingsManager, database: URL) {
        self.quickUnlockManager = quickUnlockManager
        self.settingsManager = settingsManager
        self.database = database
        self.settingsState = SettingsState(protection: quickUnlockManager.protection(for: database.lastPathComponent),
                                           openOnStartup: database == settingsManager.defaultDatabaseURL)
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
        let cell = SwitchCell(style: .default, reuseIdentifier: nil)
        cell.onSwitchValueChanged = { [weak self] isBiometryOn in
            self?.settingsState.setBiometryOn(isBiometryOn)
        }
        cell.isOn = settingsState.hasBiometry
        cell.isEnabled = true
        cell.textLabel?.text = text
        return cell
    }()

    private lazy var passcodeCell: SwitchCell = {
        let cell = SwitchCell(style: .default, reuseIdentifier: nil)
        cell.onSwitchValueChanged = { [weak self] isOn in
            guard let self else { return }
            guard isOn else {
                self.settingsState.setPasscode(nil)
                return
            }
            let passcodeView = PasscodeView(scenario: .init(steps: [
                .init(type: .create),
                .init(type: .repeat)
            ], onComplete: { [weak self] passcode in
                guard let self else { return }
                self.settingsState.setPasscode(passcode)
                self.navigationController?.popViewController(animated: true)
            }))
            let controller = UIHostingController(rootView: passcodeView)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        cell.isOn = settingsState.hasPasscode
        cell.isEnabled = true
        cell.textLabel?.text = "Passcode"
        return cell
    }()

    private lazy var openOnStartupCell: SwitchCell = {
        let cell = SwitchCell(style: .default, reuseIdentifier: nil)
        cell.onSwitchValueChanged = { [weak self] openOnStartup in
            self?.settingsState.setOpenOnStartup(openOnStartup)
        }
        cell.isOn = settingsManager.defaultDatabaseURL == database
        cell.isEnabled = true
        cell.textLabel?.text = "Open on startup"
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
        passcodeCell.isOn = settingsState.hasPasscode
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

        let sectionProtection: Section = .protection
        snapshot.appendSections([sectionProtection])
        snapshot.appendItems([.biometricAuth, .passcode], toSection: sectionProtection)

        let sectionOpenOnStartup: Section = .openOnStartup
        snapshot.appendSections([sectionOpenOnStartup])
        snapshot.appendItems([.openOnStartup], toSection: sectionOpenOnStartup)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    @objc
    private func saveTapped() {
        do {
            if settingsState.protectionChanged {
                if let currentProtection = settingsState.currentProtection {
                    try quickUnlockManager.setProtection(currentProtection, for: database.lastPathComponent)
                } else {
                    try quickUnlockManager.deleteProtection(for: database.lastPathComponent)
                }
            }
            if settingsState.openOnStartupChanged {
                self.settingsManager.defaultDatabaseURL = settingsState.currentOpenOnStartup ? self.database : nil
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
        case protection
        case openOnStartup
    }

    enum Element: String {
        case biometricAuth, passcode, openOnStartup
    }

    final class DiffableDataSource: UITableViewDiffableDataSource<Section, Element> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let section = snapshot().sectionIdentifiers[section]
            switch section {
            case .protection:
                return "Quick unlock"
            case .openOnStartup:
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
                case .openOnStartup:
                    return self.openOnStartupCell
                }
            }
        )
    }
}
