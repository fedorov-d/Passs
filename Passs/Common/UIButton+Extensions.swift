//
//  UIButton+Extension.swift
//  Passs
//
//  Created by Dmitry Fedorov on 10.02.2022.
//

import UIKit

extension UIButton {
    private func image(withColor color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.setBackgroundImage(image(withColor: color), for: state)
    }

    func removeAllActions(for controlEvent: UIControl.Event = .touchUpInside) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: controlEvent)?.forEach { selector in
                removeTarget(target, action: Selector(selector), for: controlEvent)
            }
        }
    }
}
