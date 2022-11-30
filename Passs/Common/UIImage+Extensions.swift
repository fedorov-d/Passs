//
//  UIImage+Extensions.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.01.2022.
//

import UIKit

extension UIImage {
    func tinted(with color: UIColor) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
