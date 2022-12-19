//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit
import SnapKit
import Combine

protocol PasswordsSeachResultsDispalyController: AnyObject {
    var items: [PassItem] { get set }
    var sectionTitle: String? { get set }
}

class PasswordsViewController: UIViewController, PasswordsSeachResultsDispalyController {
    var items: [PassItem] {
        didSet {
//            noItemsLabel.isHidden = !items.isEmpty
            tableView.reloadData()
        }
    }

    var sectionTitle: String?

    private let pasteboardManager: PasteboardManager
    private let recentPasswordsManager: RecentPasswordsManager
    private let credentialsSelectionManager: CredentialsSelectionManager?

    private var subscriptionSet = Set<AnyCancellable>()

    init(
        title: String? = nil,
        items: [PassItem] = [],
        pasteboardManager: PasteboardManager,
        recentPasswordsManager: RecentPasswordsManager,
        credentialsSelectionManager: CredentialsSelectionManager?
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

    private let cellId = "passwords.cell.id"

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 10
        }
//        tableView.backgroundView = noItemsLabel
        return tableView
    }()

    private lazy var noItemsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.text = "No items"
        return label
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

        setCancelNavigationItemIfNeeded(with: credentialsSelectionManager)

        tableView.reloadData()
        setupKeyboardAvoidance(for: tableView, subscriptionSet: &subscriptionSet)
    }

}

extension PasswordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
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
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        swipeActionConfiguration(with: "Copy username") { [unowned self] in
            let item = self.items[indexPath.row]
            self.copyUsername(item)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        swipeActionConfiguration(with: "Copy password") { [unowned self] in
            let item = self.items[indexPath.row]
            self.copyPassword(item)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        credentialsSelectionManager?.onCredentialsSelected(item)
    }

    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] menuElements in
            guard let item = self?.items[indexPath.row] else { return nil }
            let copyUsernameAction = UIAction(title: "Copy username",
                                   image: UIImage(systemName: "doc.on.doc.fill")) { action in
                self?.copyUsername(item)
            }
            let copyPasswordAction = UIAction(title: "Copy password",
                                   image: UIImage(systemName: "doc.on.doc")) { action in
                self?.copyPassword(item)
            }
            let generateQRAction = UIAction(title: "Show QR code",
                                            image: UIImage(systemName: "qrcode")) { action in

            }
            return UIMenu(title: item.username ?? "",
                          children: [copyUsernameAction, copyPasswordAction, generateQRAction])
        })
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

    @objc
    private func copyUsername(_ passItem: PassItem) {
        guard let username = passItem.username else { return }
        self.pasteboardManager.copy(username)
        self.recentPasswordsManager.push(item: passItem)
    }

    @objc
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
