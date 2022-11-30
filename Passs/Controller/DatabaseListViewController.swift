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

class DatabaseListViewController: UIViewController {
    private let databasesProvider: DatabasesProvider
    private let localAuthManager: LocalAuthManager
    private let passDatabaseManager: PassDatabaseManager
    
    private let cellId = "database.cell.id"

    private let completion: () -> Void
    private let enterPassword: (_: StoredDatabase) -> Void

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
        enterPassword: @escaping (_: StoredDatabase) -> Void,
        completion: @escaping () -> Void
    ) {
        self.databasesProvider = databasesProvider
        self.passDatabaseManager = passDatabaseManager
        self.localAuthManager = localAuthManager
        self.enterPassword = enterPassword
        self.completion = completion
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(importTapped)
        )
        databasesProvider.loadStoredDatabases()
    }

    private func presentEnterPassword(for database: StoredDatabase) {
        self.enterPassword(database)
    }

    private func handlePasswordError(_ error: Error, for database: StoredDatabase) {
        switch error {
        case is LAError:
            let error = error as! LAError
            if error.code == .userFallback || error.code == .biometryLockout {
                self.presentEnterPassword(for: database)
            }
        case is KeychainError:
            let error = error as! KeychainError
            if error == .itemNotFound {
                self.presentEnterPassword(for: database)
            }
        default: break
        }
    }
}

extension DatabaseListViewController {
    @objc func importTapped() {
        let documentPickerController = UIDocumentPickerViewController.keepassDatabasesPicker()
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
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
        databasesProvider.databases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let database = databasesProvider.databases[indexPath.row]
        cell.textLabel?.text = database.name
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(systemName: "square.stack.3d.up")?.tinted(with: .systemBlue)

        guard let modificationDate = database.modificationDate,
              let detailTextLabel = cell.detailTextLabel else { return cell }

        let detailTextLabelColor: UIColor = .secondaryLabel
        let detailTextLabelFont = UIFont.preferredFont(forTextStyle: .caption1)
        detailTextLabel.textColor = detailTextLabelColor
        detailTextLabel.font = detailTextLabelFont
        detailTextLabel.text = "";

        if Date().timeIntervalSince(modificationDate) > Constants.markAsUpdatedTimeout {
            detailTextLabel.attributedText = lastUpdateDateAttributedString(from: modificationDate,
                                                                            font: detailTextLabelFont,
                                                                            textColor: detailTextLabelColor)
        } else {
            detailTextLabel.text = "Last modified on " + dateFormatter.string(from: modificationDate)
        }
        return cell
    }
}

extension DatabaseListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let database = databasesProvider.databases[indexPath.row]
        localAuthManager.unlockData(for: database.url.lastPathComponent) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let unlockData):
                do {
                    try self.passDatabaseManager.load(
                        databaseURL: database.url,
                        password: unlockData.password,
                        keyFileData: unlockData.keyFileData
                    )
                    self.completion()
                } catch (let error) {
                    self.handlePasswordError(error, for: database)
                }
            case .failure(let error):
                self.handlePasswordError(error, for: database)
            }
        }
    }
}

extension DatabaseListViewController: DatabasesProviderDelegate {
    func didLoadStoredDatabases() {
        tableView.reloadData()
    }

    func didAddDatabase(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.performBatchUpdates {
            tableView.insertRows(at: [indexPath], with: .top)
        } completion: { _ in }
    }

    func didUpdateDatabase(at index: Int) {
        tableView.reloadRows(
            at: [IndexPath(row: index, section: 0)],
            with: .automatic
        )
    }
}

fileprivate extension DatabaseListViewController {
    func lastUpdateDateAttributedString(from date: Date, font: UIFont, textColor: UIColor) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.font : font.italics(),
                          NSAttributedString.Key.foregroundColor: textColor]
        let resultString = NSMutableAttributedString(
            string: "Last modified on ",
            attributes: [NSAttributedString.Key.font : font,
                         NSAttributedString.Key.foregroundColor: textColor]
        )
        resultString.append(NSAttributedString(string: dateFormatter.string(from: date),
                                               attributes: attributes))
        return resultString.copy() as! NSAttributedString
    }
}

fileprivate extension DatabaseListViewController {
    enum Constants {
        static let markAsUpdatedTimeout: TimeInterval = 1800
    }
}
