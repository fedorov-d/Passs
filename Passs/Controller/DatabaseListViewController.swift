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
    
    private let cellId = "database.cell.id"

    private let onDatabaseOpened: () -> Void
    private let onAskForPassword: (_: URL) -> Void

    private var subscriptionSet = Set<AnyCancellable>()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: cellId)
        return tableView
    }()
    
    init(
        databasesProvider: DatabasesProvider,
        passDatabaseManager: PassDatabaseManager,
        localAuthManager: LocalAuthManager,
        credentialsSelectionManager: CredentialsSelectionManager?,
        onAskForPassword: @escaping (_: URL) -> Void,
        onDatabaseOpened: @escaping () -> Void
    ) {
        self.databasesProvider = databasesProvider
        self.passDatabaseManager = passDatabaseManager
        self.localAuthManager = localAuthManager
        self.credentialsSelectionManager = credentialsSelectionManager
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Databases"
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
        applicationDidBecomeActivePublisher()
            .sink { [weak self] in
                guard let self else { return }
                self.tableView.reloadData()
                self.unlockDatabaseIfNeeded()
            }
            .store(in: &subscriptionSet)
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

extension DatabaseListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        databasesProvider.databaseURLs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let databaseURL =  databasesProvider.databaseURLs[indexPath.row]
        cell.textLabel?.text = databaseURL.lastPathComponent
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(systemName: "square.stack.3d.up")?.tinted(with: .systemBlue)
        cell.detailTextLabel?.textColor = .secondaryLabel
        if let date = modificationDate(forFileAtPath: databaseURL.path),
           let detailTextLabel = cell.detailTextLabel {
            let font = Date().timeIntervalSince(date) < 1800 ? detailTextLabel.font.italics() : detailTextLabel.font
            let lastModifiedText = lastUpdateDateAttributedString(from: date,
                                                                  font: font!,
                                                                  textColor: detailTextLabel.textColor)
            detailTextLabel.attributedText = lastModifiedText
        }
        return cell
    }
}

extension DatabaseListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let database = databasesProvider.databaseURLs[indexPath.row]
        unlockDatabase(at: database)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] action, view, closure in
            self?.databasesProvider.deleteDatabase(at: indexPath.row)
            closure(true)
        }
        action.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [action])
    }
}

extension DatabaseListViewController: DatabasesProviderDelegate {
    func didAddDatabase(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.performBatchUpdates {
            tableView.insertRows(at: [indexPath], with: .top)
        } completion: { _ in }
    }

    func didDeleteDatabase(at index: Int, name: String) {
        try? localAuthManager.clearUnlockData(for: name)
        tableView.deleteRows(
            at: [IndexPath(row: index, section: 0)],
            with: .automatic
        )
    }
}

fileprivate extension DatabaseListViewController {
    func modificationDate(forFileAtPath path: String) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
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
}

extension DatabaseListViewController: DefaultDatabaseUnlock {
    func unlockDatabaseIfNeeded() {
        guard databasesProvider.databaseURLs.count == 1,
              let databaseToUnlock = databasesProvider.databaseURLs.first,
              !localAuthManager.isFetchingUnlockData,
              !passDatabaseManager.isDatabaseUnlocked else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.unlockDatabase(at: databaseToUnlock)
        }
    }

    func unlockDatabase(at url: URL) {
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

fileprivate extension DatabaseListViewController {
    enum Constants {
        static let markAsUpdatedTimeout: TimeInterval = 1800
    }
}
