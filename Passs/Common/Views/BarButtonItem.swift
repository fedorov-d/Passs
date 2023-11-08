//
//  BarButtonItem.swift
//  Passs
//
//  Created by Dmitry on 06.12.2022.
//

import UIKit

class BarButtonItem: UIBarButtonItem {
    private(set) var buttonAction: (() -> Void)?
    
    func configure(with action: @escaping () -> Void) {
        self.buttonAction = action
        self.target = self
        self.action = #selector(onAction)
    }

    @objc
    func onAction() {
        buttonAction?()
    }
}
