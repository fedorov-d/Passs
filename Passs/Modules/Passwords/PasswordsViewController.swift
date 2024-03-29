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
            tableView.reloadData()
        }
    }

    var sectionTitle: String?

    private let pasteboardManager: PasteboardManager
    private let recentPasswordsManager: RecentPasswordsManager
    private let credentialsSelectionManager: CredentialsSelectionManager?
    private let footerViewProvider: (() -> UIView)?
    private var onItemSelect: ((PassItem) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    init(title: String? = "Passwords",
         footerViewProvider: (() -> UIView)? = nil,
         sectionTitle: String? = nil,
         items: [PassItem] = [],
         onItemSelect: ((PassItem) -> Void)? = nil,
         pasteboardManager: PasteboardManager,
         recentPasswordsManager: RecentPasswordsManager,
         credentialsSelectionManager: CredentialsSelectionManager?) {
        self.footerViewProvider = footerViewProvider
        self.sectionTitle = sectionTitle
        self.items = items
        self.onItemSelect = onItemSelect
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
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 16))
        if let headerView = footerViewProvider?() {
            tableView.tableFooterView = headerView
            tableView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: 0, height: 64)
        }
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
        setupKeyboardAvoidance(for: tableView, cancellables: &cancellables)
    }

}

extension PasswordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let item = items[indexPath.row]

        let isTitleEmpty = (item.title ?? "").isEmpty
        let textLabelFont = UIFont.preferredFont(forTextStyle: .body)

        let title = isTitleEmpty ? "No title" : item.title!
        cell.textLabel?.text = title
        cell.textLabel?.font = isTitleEmpty ? textLabelFont.italics() : textLabelFont

        let isUsernameEmpty = (item.username ?? "").isEmpty
        let username = isUsernameEmpty ? "No username" : item.username!
        let detailTextLabelFont = UIFont.preferredFont(forTextStyle: .caption1)

        cell.detailTextLabel?.text = username
        cell.detailTextLabel?.font = isUsernameEmpty ? detailTextLabelFont.italics() : detailTextLabelFont
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(systemName: item.iconSymbol)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text = sectionTitle
        label.font = .preferredFont(forTextStyle: .footnote)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label.embedded(edges: .init(top: 4, leading: 16, bottom: 8, trailing: 16))
    }
}

extension PasswordsViewController: UITableViewDelegate {
#if !CREDENTIALS_PROVIDER_EXTENSION
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
#endif

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
#if CREDENTIALS_PROVIDER_EXTENSION
        credentialsSelectionManager?.onCredentialsSelected(item)
#else
        onItemSelect?(item)
#endif
    }

#if !CREDENTIALS_PROVIDER_EXTENSION
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] menuElements in
            guard let item = self?.items[indexPath.row] else { fatalError() }
            var menuItems = [UIAction]()
            if let username = item.username, !username.isEmpty {
                let copyUsernameAction = UIAction(title: "Copy username",
                                                  image: UIImage(systemName: "doc.on.doc")) { action in
                    self?.copyUsername(item)
                }
                menuItems.append(copyUsernameAction)
            }
            if let password = item.password, !password.isEmpty {
                let copyPasswordAction = UIAction(title: "Copy password",
                                                  image: UIImage(systemName: "doc.on.doc")) { action in
                    self?.copyPassword(item)
                }
                menuItems.append(copyPasswordAction)

                let generateQRAction = UIAction(title: "Generate QR code",
                                                image: UIImage(systemName: "qrcode")) { action in
                    self?.presentQRCode(for: password)
                }
                menuItems.append(generateQRAction)
            }
            if let url = item.url.flatMap({ URL(string: $0) }) {
                let generateQRAction = UIAction(title: "Open link",
                                                image: UIImage(systemName: "arrow.up.right.square")) { action in
                    UIApplication.shared.openURL(url)
                }
                menuItems.append(generateQRAction)
            }
            return UIMenu(title: "",
                          children: menuItems)
        })
    }
#endif
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
        action.backgroundColor = .keepCyan
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

extension PasswordsViewController {
    func presentQRCode(for password: String) {
        let qrCodeController = QRCodeViewController(string: password,
                                                    qrCodeManager: QRCodeManager())
        self.present(qrCodeController, animated: true)
    }
}

extension Array where Element == PassItem {
    func sortedByName() -> [Element] {
        return self.sorted {
            $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
    }
}
