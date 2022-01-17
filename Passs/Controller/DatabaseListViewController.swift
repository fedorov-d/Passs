//
//  DatabaseListViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class DatabaseListViewController: UIViewController {
    private let databasesProvider: DatabasesProvider
    
    private let cellId = "database.cell.id"
    private let completion: (URL, String) -> ()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        return tableView
    }()

    private lazy var importDatabaseButton: UIButton = {
        let button = UIButton()
        button.setTitle("Import database", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.darkGray, for: .highlighted)
        button.addTarget(self, action: #selector(importTapped), for: .touchUpInside)
        return button
    }()
    
    init(databasesProvider: DatabasesProvider, completion: @escaping (URL, String) -> ()) {
        self.databasesProvider = databasesProvider
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()

        view.addSubview(tableView)
        view.addSubview(importDatabaseButton)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        importDatabaseButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom - 24)
            make.height.equalTo(44)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Databases"
        self.navigationItem.backButtonTitle = ""
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
            documentPickerController = UIDocumentPickerViewController(documentTypes: ["com.df.passs.kdbx", "com.df.passs.kdb"], in: .import)
        }
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }

}

extension DatabaseListViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let indexPath = IndexPath(row: databasesProvider.databases.count, section: 0)
        do {
            try databasesProvider.addDatabase(from: url)
            tableView.performBatchUpdates {
                tableView.insertRows(at: [indexPath], with: .top)
            } completion: { _ in }
        } catch (let error) {

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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        let database = databasesProvider.databases[indexPath.row]
        cell?.textLabel?.text = database.name
        return cell ?? UITableViewCell()
    }

}

extension DatabaseListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let database = databasesProvider.databases[indexPath.row]
        let enterPasswordController = EnterPasswordViewController { [weak self] password in
            self?.dismiss(animated: true)
            self?.completion(database.url, password)
        }
//        let navigationController = UINavigationController(rootViewController: enterPasswordController)
        present(enterPasswordController, animated: true)
    }

}
