//
//  DatabaseListViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import LocalAuthentication
import Combine

protocol DefaultDatabaseUnlock: AnyObject {
    func unlockDatabaseIfNeeded()
}

class DatabaseListViewController: UIViewController {
    private let databasesProvider: DatabasesProvider
    private let localAuthManager: LocalAuthManager
    private let passDatabaseManager: PassDatabaseManager
    private let credentialsSelectionManager: CredentialsSelectionManager?
    fileprivate let settingsManager: SettingsManager
    
    private let cellId = "database.cell.id"

    private let onDatabaseOpened: () -> Void
    private let onAskForPassword: (_: URL) -> Void

    private var cancellables = Set<AnyCancellable>()

    private lazy var dataSource = makeDataSource()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: cellId)
        return tableView
    }()

    private lazy var noDatabasesView: UIView = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "No databases"
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    init(databasesProvider: DatabasesProvider,
         passDatabaseManager: PassDatabaseManager,
         localAuthManager: LocalAuthManager,
         credentialsSelectionManager: CredentialsSelectionManager?,
         settingsManager: SettingsManager,
         onAskForPassword: @escaping (_: URL) -> Void,
         onDatabaseOpened: @escaping () -> Void) {
        self.databasesProvider = databasesProvider
        self.passDatabaseManager = passDatabaseManager
        self.localAuthManager = localAuthManager
        self.credentialsSelectionManager = credentialsSelectionManager
        self.settingsManager = settingsManager
        self.onAskForPassword = onAskForPassword
        self.onDatabaseOpened = onDatabaseOpened
        super.init(nibName: nil, bundle: nil)
        self.databasesProvider.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.backgroundView = noDatabasesView
    }

    private var ignoreApplicationDidBecomeActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        updateDataSource()

        self.navigationItem.backButtonTitle = ""

        if credentialsSelectionManager == nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(importTapped)
            )
        } else {
            setCancelNavigationItemIfNeeded(with: credentialsSelectionManager)
        }

        updateNoDatabasesLabelVisibility()

        applicationWillResignActivePublisher()
            .sink { [weak self] _ in
                self?.ignoreApplicationDidBecomeActive = true
            }
            .store(in: &cancellables)

        applicationDidEnterBackground()
            .sink { [weak self] in
                self?.ignoreApplicationDidBecomeActive = false
            }
            .store(in: &cancellables)

        applicationDidBecomeActivePublisher()
            .filter { [weak self] _ in
                guard let self else { return true }
                return !self.ignoreApplicationDidBecomeActive
            }
            .sink { [weak self] in
                guard let self else { return }
                self.tableView.reloadData()
                self.unlockDatabaseIfNeeded()
            }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passDatabaseManager.lockDatabase()
    }

    private func presentEnterPassword(forDatabaseAt url: URL) {
        self.onAskForPassword(url)
    }

    private func handlePasswordError(_ error: Error, forDatabaseAt url: URL) {
        switch error {
        case is LAError:
            let error = error as! LAError
            if error.code == .userFallback || error.code == .biometryLockout {
                self.presentEnterPassword(forDatabaseAt: url)
            }
        case is KeychainError:
            let error = error as! KeychainError
            if error == .itemNotFound {
                self.presentEnterPassword(forDatabaseAt: url)
            }
        default: break
        }
    }
}

extension DatabaseListViewController {
    @objc
    func importTapped() {
        let documentPickerController = UIDocumentPickerViewController.keepassDatabasesPicker()
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }

    @objc
    func cancelTapped() {
        credentialsSelectionManager?.onCancel()
    }
}

extension DatabaseListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            try databasesProvider.addDatabase(from: url)
        } catch (let error) {
            Swift.debugPrint(error)
        }
    }
}

extension DatabaseListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionID = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let databaseURL = self.dataSource.snapshot().itemIdentifiers(inSection: sectionID)[indexPath.row]
        unlockDatabase(at: databaseURL)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] action, view, closure in
            guard let self else { return }
            let sectionID = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let databaseURL = self.dataSource.snapshot().itemIdentifiers(inSection: sectionID)[indexPath.row]
            self.deleteDatabase(at: databaseURL)
            closure(true)
        }
        action.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] menuElements in
            guard let self else { fatalError() }
            let sectionID = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let databaseURL = self.dataSource.snapshot().itemIdentifiers(inSection: sectionID)[indexPath.row]
            let unlockAction = UIAction(title: "Unlock",
                                        image: UIImage(systemName: "lock.open")) { [weak self] action in
                guard let self else { return }
                self.unlockDatabase(at: databaseURL)
            }
            let deleteAction = UIAction(title: "Delete",
                                        image: UIImage(systemName: "trash"),
                                        attributes: .destructive) { [weak self] action in
                guard let self else { return }
                self.deleteDatabase(at: databaseURL)
            }
            guard self.databasesProvider.databaseURLs.count > 1, sectionID != .default else {
                return UIMenu(title: "", children: [unlockAction, deleteAction])
            }
            let makeDefaultAction = UIAction(
                title: "Make default",
                image: UIImage(systemName: "externaldrive.badge.checkmark")
            ) { [weak self] action in
                guard let self else { return }
                self.settingsManager.defaultDatabaseURL = databaseURL
                self.updateDataSource()
            }
            return UIMenu(title: "", children: [unlockAction, makeDefaultAction, deleteAction])
        })
    }
}

extension DatabaseListViewController: DatabasesProviderDelegate {
    func didAddDatabase(at index: Int) {
        updateDataSource()
        updateNoDatabasesLabelVisibility()
    }

    func didDeleteDatabase(at databaseURL: URL, name: String) {
        try? localAuthManager.clearUnlockData(for: name)
        updateDataSource()
        updateNoDatabasesLabelVisibility()
    }

    private func updateNoDatabasesLabelVisibility() {
        noDatabasesView.isHidden = !databasesProvider.databaseURLs.isEmpty
        title = databasesProvider.databaseURLs.isEmpty ? "" : "Databases"
    }
}

fileprivate extension DatabaseListViewController {
    func modificationDate(forFileAtURL url: URL) -> Date? {
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch let error {
            print(error)
            return nil
        }
    }

    func lastUpdateDateAttributedString(from date: Date, font: UIFont, textColor: UIColor) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.font : font,
                          NSAttributedString.Key.foregroundColor: textColor]
        let resultString = NSMutableAttributedString(
            string: "Last modified on ",
            attributes: [NSAttributedString.Key.font : font.noTraits(),
                         NSAttributedString.Key.foregroundColor: textColor]
        )
        resultString.append(NSAttributedString(string: dateFormatter.string(from: date),
                                               attributes: attributes))
        return resultString.copy() as! NSAttributedString
    }

    func deleteDatabase(at databaseURL: URL) {
        if settingsManager.defaultDatabaseURL == databaseURL {
            settingsManager.defaultDatabaseURL = nil
        }
        databasesProvider.deleteDatabase(at: databaseURL)
    }

    func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, URL>()
        var urls = databasesProvider.databaseURLs
        guard !urls.isEmpty else {
            dataSource.apply(snapshot, animatingDifferences: true)
            return            
        }
        if let defaultDatabaseURL = settingsManager.defaultDatabaseURL ?? (urls.count == 1 ? urls.first : nil)  {
            if let index = urls.firstIndex(of: defaultDatabaseURL) {
                urls.remove(at: index)
            }
            snapshot.appendSections([.default])
            snapshot.appendItems([defaultDatabaseURL], toSection: .default)
        }
        if !urls.isEmpty {
            snapshot.appendSections([.other])
            snapshot.appendItems(urls, toSection: .other)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension DatabaseListViewController: DefaultDatabaseUnlock {
    func unlockDatabaseIfNeeded() {
        guard presentedViewController == nil,
              let defaultDatabase = settingsManager.defaultDatabaseURL,
              !localAuthManager.isFetchingUnlockData,
              !passDatabaseManager.isDatabaseUnlocked else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.unlockDatabase(at: defaultDatabase)
        }
    }

    func unlockDatabase(at url: URL) {
        guard let url = databasesProvider.databaseURLs.first(where: {
            $0.lastPathComponent == url.lastPathComponent
        }) else {
            Swift.debugPrint("database doesn't contain default URL")
            return
        }
        localAuthManager.unlockData(for: url.lastPathComponent) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let unlockData):
                do {
                    try self.passDatabaseManager.unlockDatabase(
                        with: url,
                        password: unlockData.password,
                        keyFileData: unlockData.keyFileData
                    )
                    self.onDatabaseOpened()
                } catch (let error) {
                    self.handlePasswordError(error, forDatabaseAt: url)
                }
            case .failure(let error):
                self.handlePasswordError(error, forDatabaseAt: url)
            }
        }
    }
}

private extension DatabaseListViewController {
    enum Section: String {
        case `default`
        case other
    }

    final class DiffableDataSource: UITableViewDiffableDataSource<Section, URL> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            snapshot().sectionIdentifiers[section].rawValue.capitalized
        }
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, URL> {
        let reuseIdentifier = cellId
        return DiffableDataSource(
            tableView: tableView,
            cellProvider: { [weak self]  tableView, indexPath, databaseURL in
                guard let self else { return UITableViewCell() }
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: reuseIdentifier,
                    for: indexPath
                )

                cell.textLabel?.text = databaseURL.lastPathComponent
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "square.stack.3d.up")
                guard let detailTextLabel = cell.detailTextLabel,
                      let date = self.modificationDate(forFileAtURL: databaseURL) else { return cell }
                let secondaryLabel: UIColor = .secondaryLabel
                detailTextLabel.textColor = secondaryLabel
                let font = Date().timeIntervalSince(date) < 1800 ? detailTextLabel.font.italics() : detailTextLabel.font
                let lastModifiedText = self.lastUpdateDateAttributedString(from: date,
                                                                           font: font!,
                                                                           textColor: secondaryLabel)
                detailTextLabel.attributedText = lastModifiedText
                return cell
            }
        )
    }
}

fileprivate extension DatabaseListViewController {
    enum Constants {
        static let markAsUpdatedTimeout: TimeInterval = 1800
    }
}
