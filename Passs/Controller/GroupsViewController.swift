//
//  GroupsViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.01.2022.
//

import UIKit
import Combine

class GroupsViewController: UIViewController {
    private let databaseManager: PassDatabaseManager
    private let recentPasswordsManager: RecentPasswordsManager
    private let groupSelected: (PassGroup) -> Void
    private let searchResultsControllerProvider: () -> PasswordsSeachResultsDispalyController & UIViewController

    private var subscriptionSet = Set<AnyCancellable>()

    init(
        databaseManager: PassDatabaseManager,
        recentPasswordsManager: RecentPasswordsManager,
        searchResultsControllerProvider: @escaping () -> PasswordsSeachResultsDispalyController & UIViewController,
        groupSelected: @escaping (PassGroup) -> Void
    ) {
        precondition(databaseManager.passwordGroups?.count ?? 0 > 0)
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

    private let cellId = "groups.cell.id"

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 10
        }
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
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.title = self.databaseManager.databaseName

        tableView.reloadData()

        navigationItem.searchController = UISearchController(searchResultsController: searchResultsControllerProvider())
        navigationItem.searchController?.searchResultsUpdater = self
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = false

        keyboardWillShowPublisher()
            .sink { [weak self] params in
                guard let self else { return }
                var currentInset = self.tableView.contentInset
                currentInset.bottom = params.frameEnd.height - self.view.safeAreaInsets.bottom
                self.tableView.contentInset = currentInset
                self.tableView.separatorInset = currentInset
            }
            .store(in: &subscriptionSet)

        keyboardWillHidePublisher()
            .sink { [weak self] params in
                guard let self else { return }
                var currentInset = self.tableView.contentInset
                currentInset.bottom = 0
                self.tableView.contentInset = currentInset
                self.tableView.separatorInset = currentInset
            }
            .store(in: &subscriptionSet)
    }
}

extension GroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let passwordsController = searchController.searchResultsController
                as? PasswordsSeachResultsDispalyController & UIViewController,
        let groups = databaseManager.passwordGroups else { return }
        let items = groups.flatMap { $0.items }
        let text = searchController.searchBar.text
        if text == nil || text!.isEmpty {
            let items = recentPasswordsManager.matchingItems(for: items)
            guard items.count > 0 else { return }
            passwordsController.view.isHidden = false
            passwordsController.sectionTitle = "Recent items"
            passwordsController.items = items
            return
        }
        let matchingItems = items.filter { item in
            item.title?.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") ?? false
        }
        passwordsController.sectionTitle = matchingItems.isEmpty ? "No matching items" : "Matching items"
        passwordsController.items = matchingItems
    }

}

extension GroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return databaseManager.passwordGroups?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        guard let group = databaseManager.passwordGroups?[indexPath.row] else { fatalError() }
        cell.textLabel?.text = group.title
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(systemName: "folder")?.tinted(with: .systemBlue)
        return cell
    }

}

extension GroupsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let group = databaseManager.passwordGroups?[indexPath.row] else { return }
        groupSelected(group)
    }

}
