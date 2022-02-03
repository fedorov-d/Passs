//
//  UIButton+Helpers.swift
//  Passs
//
//  Created by Dmitry Fedorov on 02.02.2022.
//

import UIKit

extension UIButton {

    static func roundedButton(with icon: UIImage) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .secondaryLabel
        button.layer.masksToBounds = true
        button.setImage(icon, for: .normal)
        return button
    }

}
