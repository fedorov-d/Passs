//
//  DatabaseListViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 07.04.2021.
//

import UIKit

class DatabaseListViewController: UIViewController {
    private let databasesProvider: DatabasesProvider
    
    private let cellId = "database.cell.id"
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        return tableView
    }()
    
    init(databasesProvider: DatabasesProvider) {
        self.databasesProvider = databasesProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Databases"
    }
}

extension DatabaseListViewController: UITableViewDataSource, UITableViewDelegate {
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
