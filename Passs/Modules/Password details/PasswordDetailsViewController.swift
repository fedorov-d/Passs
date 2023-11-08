//
//  PasswordDetailsViewController.swift
//  Passs
//
//  Created by Dmitry on 01.05.2023.
//

import UIKit

final class PasswordDetailsViewController: UIViewController {
    private let passItem: PassItem
    private let pasteboardManager: PasteboardManager

    init(passItem: PassItem, pasteboardManager: PasteboardManager) {
        self.passItem = passItem
        self.pasteboardManager = pasteboardManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var dataSource = makeDataSource()
    private var isPasswordVisible = false

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
            tableView.sectionFooterHeight = .leastNonzeroMagnitude
        }
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: textFieldCellID)
        tableView.register(SelectKeyButtonCell.self, forCellReuseIdentifier: buttonCellID)
        return tableView
    }()

    private let textFieldCellID = "textFieldCellID"
    private let buttonCellID = "buttonCellID"

    private func makeButton(image: UIImage? = nil, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = passItem.title
        tableView.dataSource = dataSource
        updateDataSource()
    }

    func updateDataSource(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Element>()
        let usernameSection: Section = .titled("Username")
        snapshot.appendSections([usernameSection])
        snapshot.appendItems([.username], toSection: usernameSection)

        let passwordSection: Section = .titled("Password")
        snapshot.appendSections([passwordSection])
        snapshot.appendItems([.password,
                              .button(id: .togglePassword,
                                      title: "Show password",
                                      action: #selector(togglePasswordVisibility))],
                             toSection: passwordSection)
        if let password = passItem.password, !password.isEmpty {
            snapshot.appendItems([.button(id: .generateQRCode,
                                          title: "Generate QR Code",
                                          action: #selector(showQRCode))],
                                 toSection: passwordSection)
        }

        if let url = passItem.url, !url.isEmpty {
            let urlSection: Section = .titled("URL")
            snapshot.appendSections([urlSection])
            snapshot.appendItems([.url], toSection: urlSection)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

}

extension PasswordDetailsViewController {
    enum ButtonID: String {
        case togglePassword
        case generateQRCode
    }

    enum Section: Hashable {
        case titled(_ title: String)
    }

    enum Element: Hashable {
        case username, password, button(id: ButtonID, title: String, action: Selector), url, icon
    }

    final class DiffableDataSource: UITableViewDiffableDataSource<Section, Element> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let section = snapshot().sectionIdentifiers[section]
            switch section {
            case .titled(let title):
                return title
            }
        }
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, Element> {
        return DiffableDataSource(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, element in
                guard let self else { return UITableViewCell() }
                if case .button(_, let title, let action) = element {
                    return self.showButtonCell(title: title, action: action, at: indexPath)
                } else {
                    return self.textFieldCell(for: element, atIndexPath: indexPath)
                }
            }
        )
    }

    private func showButtonCell(title: String, action: Selector, at indexPath: IndexPath) -> SelectKeyButtonCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellID,
                                                       for: indexPath) as? SelectKeyButtonCell else { fatalError() }
        cell.title = title
        cell.setTarget(self, action: action)
        return cell
    }

    private func textFieldCell(for element: Element, atIndexPath indexPath: IndexPath) -> TextFieldCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: textFieldCellID,
                                                       for: indexPath) as? TextFieldCell else { fatalError() }
        cell.isEditable = false
        cell.isSecureTextEntry = false
        switch element {
        case .username:
            cell.textValue = passItem.username ?? ""
            cell.accessoryView = makeButton(image: UIImage(systemName: "doc.on.doc"), action: #selector(copyUsername))
        case .password:
            cell.textValue = passItem.password ?? ""
            cell.accessoryView = makeButton(image: UIImage(systemName: "doc.on.doc"), action: #selector(copyPassword))
        case .url:
            cell.textValue = passItem.url ?? ""
            cell.accessoryView = makeButton(image: UIImage(systemName:  "arrow.up.right.square"),
                                            action: #selector(openURL))
        case .icon:
            cell.textValue = "some icon"
        default:
            fatalError()
        }

        cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        return cell
    }
}

extension PasswordDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
        switch element {
        case .username:
            copyUsername()
        case .password:
            copyPassword()
        case .url:
            openURL()
        case .button(_, _, let action):
            perform(action)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
        updateCell(cell, with: element)
    }
}

private extension PasswordDetailsViewController {
    @objc
    func copyUsername() {
        guard let username = passItem.username else { return }
        pasteboardManager.copy(username)
        executeHapticFeedback()
        showNotification(text: "Username copied to clipboard")
    }

    @objc
    func copyPassword() {
        guard let password = passItem.password else { return }
        pasteboardManager.copy(password)
        executeHapticFeedback()
        showNotification(text: "Password copied to clipboard")
    }

    @objc
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        tableView.indexPathsForVisibleRows?.forEach { indexPath  in
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
            if let cell = self.tableView.cellForRow(at: indexPath) {
                self.updateCell(cell, with: element)
            }
        }
    }

    @objc
    func showQRCode() {
        guard let password = passItem.password else {
            fatalError("attempt to present QR code for empty password")
        }
        let qrCodeController = QRCodeViewController(string: password,
                                                    qrCodeManager: QRCodeManager())
        self.present(qrCodeController, animated: true)
    }

    @objc
    func openURL() {
        guard let url = passItem.url.flatMap({ URL(string: $0) }) else { return }
#if !CREDENTIALS_PROVIDER_EXTENSION
        UIApplication.shared.openURL(url)
#endif
    }

    private func updateCell(_ cell: UITableViewCell, with element: Element) {
        switch element {
        case .password:
            guard let cell = cell as? TextFieldCell else { break }
            cell.isSecureTextEntry = !isPasswordVisible
        case .button(let id, _, _):
            guard id == .togglePassword, let cell = cell as? SelectKeyButtonCell else { break }
            cell.title = isPasswordVisible ? "Hide password" : "Show password"
        default:
            break
        }
    }

    private func executeHapticFeedback() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }

    private func showNotification(text: String) {
        let notificationViewController = NotificationViewController(
            image: UIImage(systemName: "exclamationmark.circle")!,
            text: text
        )
        notificationViewController.show()
    }
}
