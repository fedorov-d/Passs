//
//  UnlockViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.02.2022.
//

import UIKit

class UnlockViewController: UIViewController {

    private let passDatabaseManager: PassDatabaseManager
    private let database: StoredDatabase
    private let completion: (String, Bool) -> ()

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        passDatabaseManager: PassDatabaseManager,
        database: StoredDatabase,
        completion: @escaping (String, Bool) -> ()
    ) {
        self.passDatabaseManager = passDatabaseManager
        self.database = database
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    private let cellId = "cellId"

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: cellId)
        return tableView
    }()

    private let segmentedControl: UISegmentedControl = {
        let result = UISegmentedControl(items: ["Password", "Key file"])
        result.selectedSegmentIndex = 0
        return result
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
        navigationItem.titleView = segmentedControl
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissViewController)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unlock", style: .done, target: nil, action: nil)
    }
}

extension UnlockViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Enter password"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
}

extension UnlockViewController: UITableViewDelegate {

}

extension UnlockViewController {

    @objc
    private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
