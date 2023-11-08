//
//  UITableView+Extensions.swift
//  Passs
//
//  Created by Dmitry on 08.05.2023.
//

import UIKit

extension UITableView {
    public func registerReusableCell<T: UITableViewCell>(ofClass cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: String(describing: cellType))
    }

    func dequeueReusableCell<T: UITableViewCell>(ofClass cellType: T.Type, for indexPath: IndexPath) -> T {
        dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as! T
    }
}
