//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit

class PasswordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let databaseManager: PassDatabaseManager
    private let pasteboardManager: PasteboardManager
    
    init(databaseManager: PassDatabaseManager, pasteboardManager: PasteboardManager) {
        self.databaseManager = databaseManager
        self.pasteboardManager = pasteboardManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell.id")
        return tableView
    }()
    
    // MARK: - UIViewController lifecycle
    
    override func loadView() {
        view = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.databaseManager.load()
        self.tableView.reloadData()
    }
    
    // MARK: - UITableView datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        databaseManager.passwordGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        databaseManager.passwordGroups[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id")
        let item = databaseManager.passwordGroups[indexPath.section].items[indexPath.row]
        cell?.textLabel?.text = item.title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return databaseManager.passwordGroups[section].title
    }
    
    // MARK: - UITableView delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = databaseManager.passwordGroups[indexPath.section].items[indexPath.row]
        guard let password = item.password else { return }
        pasteboardManager.copy(password: password)
    }
}

