//
//  PasswordDetailsViewController.swift
//  Passs
//
//  Created by Dmitry on 01.05.2023.
//

import UIKit

final class PasswordDetailsViewController: UIViewController {
    private let passItem: PassItem

    init(passItem: PassItem) {
        self.passItem = passItem
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

    private func makeCopyButton(action: Selector) -> UIView {
        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.addTarget(self, action: action, for: .touchUpInside)
        return copyButton
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
                              .button(title: "Show password", action: #selector(togglePasswordVisibility))],
                             toSection: passwordSection)
        if let password = passItem.password, !password.isEmpty {
            snapshot.appendItems([.button(title: "Generate QR Code", action: #selector(showQRCode))],
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
    enum Section: Hashable {
        case titled(_ title: String)
    }

    enum Element: Hashable {
        case username, password, button(title: String, action: Selector), url, icon
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
            cellProvider: { [weak self]  tableView, indexPath, element in
                guard let self else { return UITableViewCell() }
                if case .button(let title, let action) = element {
                    return showButtonCell(title: title, action: action, at: indexPath)
                } else {
                    return textFieldCell(for: element, atIndexPath: indexPath)
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
            cell.accessoryView = makeCopyButton(action: #selector(copyUsername))
        case .password:
            cell.textValue = passItem.password ?? ""
            cell.accessoryView = makeCopyButton(action: #selector(copyPassword))
        case .url:
            cell.textValue = passItem.url ?? ""
        case .icon:
            cell.textValue = "some icon"
        default:
            fatalError()
        }

        cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        return cell
    }

    func reuseIdentifier(for: Element) -> String {
        textFieldCellID
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
        case .button(_, let action):
            perform(action)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
        if case .password = element, let cell = cell as? TextFieldCell {
            cell.isSecureTextEntry = !isPasswordVisible
        }
    }
}

private extension PasswordDetailsViewController {
    @objc
    func copyUsername() {
        executeHapticFeedback()
        showNotification(text: "Username copied to clipboard")
    }

    @objc
    func copyPassword() {
        executeHapticFeedback()
        showNotification(text: "Password copied to clipboard")
    }

    @objc
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        tableView.indexPathsForVisibleRows?.forEach { indexPath  in
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let element = dataSource.snapshot().itemIdentifiers(inSection: section)[indexPath.row]
            if case .password = element, let cell = self.tableView.cellForRow(at: indexPath) as? TextFieldCell {
                cell.isSecureTextEntry = !isPasswordVisible
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
