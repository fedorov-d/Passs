//
//  QRCodeManager.swift
//  Passs
//
//  Created by Dmitry on 15.04.2023.
//

import UIKit

final class QRCodeManager {
    private let queue = DispatchQueue(label: "qr.generate.queue", attributes: .concurrent)

    func generateQRCode(from string: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        queue.async {
            let qrCodeImage = UIImage.qrCodeImage(size: size, data: string)
            DispatchQueue.main.async {
                completion(qrCodeImage)
            }
        }
    }
}
