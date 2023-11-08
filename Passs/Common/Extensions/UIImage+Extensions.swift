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

    static func qrCodeImage(size: CGSize, data string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        filter.setValue(data, forKey: "inputMessage")
        guard let ciImage = filter.outputImage else { return nil }
        let scaleX = size.width / ciImage.extent.size.width;
        let scaleY = size.height / ciImage.extent.size.height;
        let transformedCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return UIImage(ciImage: transformedCIImage)
    }
}
