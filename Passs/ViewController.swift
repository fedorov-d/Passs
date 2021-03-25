//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var groups: [PassGroup] = []
    
    override func loadView() {
        view = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let key = KPKPasswordKey(password: "za3cck2?#")!
        let compositeKey = KPKCompositeKey(keys: [key])
        let url = Bundle.main.url(forResource: "pass", withExtension: "kdbx")
        let tree = try? KPKTree(contentsOf: url, key: compositeKey)
        navigationItem.title = tree?.root?.title
        if let groups = tree?.root?.groups {
            self.groups = groups
//                .sorted(by: { group1, group2 -> Bool in
//                if group1.title == nil { return false }
//                if group2.title == nil { return true }
//                return group1.title! < group2.title!
//            })
            self.tableView.reloadData()
        }
        print("test")
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell.id")
        return tableView
    }()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        groups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id")
        let item = groups[indexPath.section].items[indexPath.row]
        cell?.textLabel?.text = item.title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = groups[indexPath.section].items[indexPath.row]
        UIPasteboard.general.string = item.password
        tableView.deselectRow(at: indexPath, animated: true)
        Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { _ in
            UIPasteboard.general.string = ""
        }
    }
}

