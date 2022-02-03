//
//  GroupsViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.01.2022.
//

import UIKit

class GroupsViewController: UIViewController {

    private let databaseManager: PassDatabaseManager
    private let recentPasswordsManager: RecentPasswordsManager
    private let groupSelected: (PassGroup) -> Void
    private let searchResultsControllerProvider: () -> PasswordsSeachResultsDispalyController & UIViewController

    init(
        databaseManager: PassDatabaseManager,
        recentPasswordsManager: RecentPasswordsManager,
        searchResultsControllerProvider: @escaping () -> PasswordsSeachResultsDispalyController & UIViewController,
        groupSelected: @escaping (PassGroup) -> Void
    ) {
        self.databaseManager = databaseManager
        self.recentPasswordsManager = recentPasswordsManager
        self.groupSelected = groupSelected
        self.searchResultsControllerProvider = searchResultsControllerProvider
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

        navigationItem.searchController = UISearchController(searchResultsController: searchResultsControllerProvider())
        navigationItem.searchController?.searchResultsUpdater = self
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = false
    }
}

extension GroupsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let passwordsController = searchController.searchResultsController
                as? PasswordsSeachResultsDispalyController & UIViewController else { return }
        let items = databaseManager.passwordGroups.flatMap { group in
            return group.items
        }
        let text = searchController.searchBar.text
        if text == nil || text!.isEmpty {
            let items = recentPasswordsManager.matchingItems(for: items)
            guard items.count > 0 else { return }
            passwordsController.view.isHidden = false
            passwordsController.sectionTitle = "Recent items"
            passwordsController.items = items
            return
        }
        passwordsController.sectionTitle = "Matching items"
        passwordsController.items = items.filter { item in
            item.title?.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") ?? false
        }
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
        cell.imageView?.image = UIImage(systemName: "folder")?.tinted(with: .systemBlue)
        return cell
    }

}

extension GroupsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = databaseManager.passwordGroups[indexPath.row]
        groupSelected(group)
    }

}
