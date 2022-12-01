//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit
import SnapKit

protocol PasswordsSeachResultsDispalyController: AnyObject {
    var items: [PassItem] { get set }
    var sectionTitle: String? { get set }
}

class PasswordsViewController: UIViewController, PasswordsSeachResultsDispalyController {
    var items: [PassItem] {
        didSet {
            tableView.reloadData()
        }
    }

    var sectionTitle: String?

    private let pasteboardManager: PasteboardManager
    private let recentPasswordsManager: RecentPasswordsManager
    private let credentialsSelectionManager: CredentialsSelectionManager

    init(
        title: String? = nil,
        items: [PassItem] = [],
        pasteboardManager: PasteboardManager,
        recentPasswordsManager: RecentPasswordsManager,
        credentialsSelectionManager: CredentialsSelectionManager
    ) {
        self.items = items
        self.pasteboardManager = pasteboardManager
        self.recentPasswordsManager = recentPasswordsManager
        self.credentialsSelectionManager = credentialsSelectionManager
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "cell.id")
        return tableView
    }()

    // MARK: - UIViewController lifecycle

    override func loadView() {
        view = UIView()
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = title
        self.navigationItem.largeTitleDisplayMode = .never
        tableView.reloadData()
    }

}

extension PasswordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.username
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(named: "key")
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        23
    }

}

extension PasswordsViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        swipeActionConfiguration(
            with: "Copy username"
        ) { [unowned self] in
            let item = self.items[indexPath.row]
            self.copyUsername(item)
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        swipeActionConfiguration(
            with: "Copy password"
        ) { [unowned self] in
            let item = self.items[indexPath.row]
            self.copyPassword(item)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        credentialsSelectionManager.onCredentialsSelected?(item)
    }
}

extension PasswordsViewController {
    private func swipeActionConfiguration(
        with title: String,
        completion: @escaping () -> Void
    ) -> UISwipeActionsConfiguration {
        let action = UIContextualAction(style: .normal, title: title) { action, view, closure in
            completion()
            closure(true)
        }
        action.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [action])
    }

    private func copyUsername(_ passItem: PassItem) {
        guard let username = passItem.username else { return }
        self.pasteboardManager.copy(username)
        self.recentPasswordsManager.push(item: passItem)
    }

    private func copyPassword(_ passItem: PassItem) {
        guard let password = passItem.password else { return }
        self.pasteboardManager.copy(password)
        self.recentPasswordsManager.push(item: passItem)
    }

}

extension Array where Element == PassItem {
    func sortedByName() -> [Element] {
        return self.sorted {
            $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
    }
}
