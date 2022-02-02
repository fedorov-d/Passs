//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit
import SnapKit

class PasswordsViewController: UIViewController {
    
    private let passwordGroup: PassGroup
    private let pasteboardManager: PasteboardManager
    
    init(passwordGroup: PassGroup, pasteboardManager: PasteboardManager) {
        self.passwordGroup = passwordGroup
        self.pasteboardManager = pasteboardManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.rowHeight = 56
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell.id")
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
        self.navigationItem.title = passwordGroup.title
        tableView.reloadData()
    }

}

extension PasswordsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        passwordGroup.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id", for: indexPath)
        let item = passwordGroup.items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.imageView?.image = UIImage(systemName: "square.on.square")?.tinted(with: .systemBlue)
        return cell
    }

}

extension PasswordsViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Copy username") { [unowned self] action, view, closure in
            let item = self.passwordGroup.items[indexPath.row]
            guard let username = item.username else { return }
            self.pasteboardManager.copy(username)
            closure(true)
        }
        action.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Copy password") { [unowned self] action, view, closure in
            let item = self.passwordGroup.items[indexPath.row]
            guard let password = item.password else { return }
            self.pasteboardManager.copy(password)
            closure(true)
        }
        action.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension PasswordsViewController: UITabBarDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = passwordGroup.items[indexPath.row]
        guard let password = item.password else { return }
        pasteboardManager.copy(password)
    }

}
