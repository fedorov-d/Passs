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

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
            tableView.sectionFooterHeight = .leastNonzeroMagnitude
        }
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: textFieldCellID)
//        tableView.register(ColoredTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: footerId)
        tableView.register(SelectKeyButtonCell.self, forCellReuseIdentifier: buttonCellID)
        return tableView
    }()

    private let textFieldCellID = "textFieldCellID"
    private let buttonCellID = "buttonCellID"

    private func makeCopyButton(action: () -> Void) -> UIView {
        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        return copyButton
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
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

    func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Element>()
        let usernameSection: Section = .titled("Username")
        snapshot.appendSections([usernameSection])
        snapshot.appendItems([.username], toSection: usernameSection)

        let passwordSection: Section = .titled("Passoword")
        snapshot.appendSections([passwordSection])
        snapshot.appendItems([.password], toSection: passwordSection)

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

    enum Element: String {
        case username, password, url, icon
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
                guard let self,
                      let cell: TextFieldCell = tableView.dequeueReusableCell(
                        withIdentifier: reuseIdentifier(for: element),
                        for: indexPath
                      ) as? TextFieldCell else { return UITableViewCell() }
                cell.isSecureTextEntry = true
                cell.isEditable = false
                switch element {
                case .username:
                    cell.textValue = passItem.username ?? ""
                case .password:
                    cell.textValue = passItem.password ?? ""
                case .url:
                    cell.textValue = passItem.url ?? ""
                case .icon:
                    cell.textValue = "some icon"
                }

                cell.accessoryView = makeCopyButton {
                }
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                return cell
            }
        )
    }

    func reuseIdentifier(for: Element) -> String {
        textFieldCellID
    }
}

extension PasswordDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }
}
