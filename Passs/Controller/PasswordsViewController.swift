//
//  ViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import UIKit
import KeePassKit
import SnapKit

class PasswordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    enum ScrollDirection {
        case none, up, down
    }
    
    private let databaseManager: PassDatabaseManager
    private let pasteboardManager: PasteboardManager
    
    init(databaseManager: PassDatabaseManager, pasteboardManager: PasteboardManager) {
        self.databaseManager = databaseManager
        self.pasteboardManager = pasteboardManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell.id")
        return tableView
    }()
    
    private var manualScrolling = false;
    private var currentScrollDirection: ScrollDirection = .none
    private var currentContentOffset = CGPoint.zero
    
    private lazy var categorySelectionView: CategorySelectorView = {
        let view = CategorySelectorView()
        view.onSelect = { [weak self] index in
            self?.tableView.scrollToRow(at: IndexPath(row: 0, section: index),
                                        at: .top,
                                        animated: true)
        }
        return view
    }()
    
    // MARK: - UIViewController lifecycle
    
    override func loadView() {
        view = UIView()
        view.addSubview(tableView)
        view.addSubview(categorySelectionView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        categorySelectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-80)
            make.height.equalTo(40)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.databaseManager.load()
        self.navigationItem.title = self.databaseManager.databaseName
        
        tableView.reloadData()
        categorySelectionView.categories = databaseManager.passwordGroups.map { $0.title ?? "Noname" }
    }
    
    // MARK: - UITableView datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        databaseManager.passwordGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        databaseManager.passwordGroups[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.id")
        let item = databaseManager.passwordGroups[indexPath.section].items[indexPath.row]
        cell?.textLabel?.text = item.title
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return databaseManager.passwordGroups[section].title
    }
    
    // MARK: - UITableView delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = databaseManager.passwordGroups[indexPath.section].items[indexPath.row]
        guard let password = item.password else { return }
        pasteboardManager.copy(password: password)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if (currentScrollDirection == .down && manualScrolling == true) {
            NSObject.cancelPreviousPerformRequests(withTarget: categorySelectionView)
            categorySelectionView.perform(#selector(categorySelectionView.willBeginDisplayCategory(at:)),
                                          with: IntWrapper(int: section),
                                          afterDelay: 0.3,
                                          inModes: [.common])
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        if (currentScrollDirection == .up && manualScrolling == true) {
            NSObject.cancelPreviousPerformRequests(withTarget: categorySelectionView)
            categorySelectionView.perform(#selector(categorySelectionView.willEndDisplayCategory(at:)),
                                          with: IntWrapper(int: section),
                                          afterDelay: 0.3,
                                          inModes: [.common])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y > currentContentOffset.y) {
            currentScrollDirection = .up;
        } else {
            currentScrollDirection = .down;
        }
        currentContentOffset = scrollView.contentOffset;
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manualScrolling = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentScrollDirection = .none
        manualScrolling = false
    }
}

