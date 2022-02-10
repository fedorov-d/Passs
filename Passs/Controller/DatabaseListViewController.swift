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
    
    private let cellId = "database.cell.id"
    private let completion: (URL, String) -> ()

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
        localAuthManager: LocalAuthManager,
        completion: @escaping (URL, String) -> ()
    ) {
        self.databasesProvider = databasesProvider
        self.localAuthManager = localAuthManager
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
    }

    private func presentEnterPassword(for database: StoredDatabase) {
        let enterPasswordController = EnterPasswordViewController { [unowned self] password, useBiometry in
            if useBiometry {
                try? localAuthManager.savePassword(password, for: database.url.lastPathComponent)
            }
            self.dismiss(animated: true)
            self.completion(database.url, password)
        }
        present(enterPasswordController, animated: true)
    }
}

extension DatabaseListViewController {

    @objc func importTapped() {
        let documentPickerController: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let types = UTType.types(
                tag: "kdbx",
                tagClass: UTTagClass.filenameExtension,
                conformingTo: nil
            )
            documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
        } else {
            documentPickerController = UIDocumentPickerViewController(documentTypes: ["com.df.passs.kdbx", "com.df.passs.kdb"], in: .open)
        }
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

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {

    }

}

extension DatabaseListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return databasesProvider.databases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let database = databasesProvider.databases[indexPath.row]
        cell.textLabel?.text = database.name
        if let modificationDate = database.modificationDate {
            cell.detailTextLabel?.text = "Last modified on " + dateFormatter.string(from: modificationDate)
        } else {
            cell.detailTextLabel?.text = ""
        }
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(systemName: "square.stack.3d.up")?.tinted(with: .systemBlue)
        return cell
    }

}

extension DatabaseListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let database = databasesProvider.databases[indexPath.row]
        localAuthManager.password(for: database.url.lastPathComponent) { result in
            switch result {
            case .success(let password):
                self.dismiss(animated: true)
                self.completion(database.url, password)
            case .failure(let error):
                switch error {
                case is LAError:
                    let error = error as! LAError
                    if error.code == .userFallback {
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
    }

}

extension DatabaseListViewController: DatabasesProviderDelegate {

    func didAddDatabase(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.performBatchUpdates {
            tableView.insertRows(at: [indexPath], with: .top)
        } completion: { _ in }
    }

}
