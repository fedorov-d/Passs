//
//  GroupsViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.01.2022.
//

import UIKit

class GroupsViewController: UIViewController {

    private let databaseManager: PassDatabaseManager
    private let groupSelected: (PassGroup) -> Void

    init(databaseManager: PassDatabaseManager, groupSelected: @escaping (PassGroup) -> Void) {
        self.databaseManager = databaseManager
        self.groupSelected = groupSelected
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell.id")
        return tableView
    }()

    override func loadView() {
        view = UIView()
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.databaseManager.load()
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationItem.title = self.databaseManager.databaseName

        tableView.reloadData()
    }
}

extension GroupsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return databaseManager.passwordGroups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id", for: indexPath)
        let group = databaseManager.passwordGroups[indexPath.row]
        cell.textLabel?.text = group.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

}

extension GroupsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = databaseManager.passwordGroups[indexPath.row]
        groupSelected(group)
    }

}
