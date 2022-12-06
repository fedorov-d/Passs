//
//  UIDocumentPickerController+Extensions.swift
//  Passs
//
//  Created by Dmitry Fedorov on 18.02.2022.
//

import UIKit
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @available(iOS 14, *)
    convenience init(supportedFilenameExtensions: [String]) {
        let types = supportedFilenameExtensions.map { filenameExtension in
            UTType.types(
                tag: filenameExtension,
                tagClass: UTTagClass.filenameExtension,
                conformingTo: nil
            )
        }.flatMap { $0 }
        self.init(forOpeningContentTypes: types)
    }

    static func keepassDatabasesPicker() -> UIDocumentPickerViewController {
        let documentPickerController: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            documentPickerController = UIDocumentPickerViewController(supportedFilenameExtensions: ["kdb", "kdbx"])
        } else {
            documentPickerController = UIDocumentPickerViewController(
                documentTypes: ["com.df.passs.kdbx", "com.df.passs.kdb"],
                in: .open
            )
        }
        return documentPickerController
    }

    static func keepassDatabaseKeyfilePicker() -> UIDocumentPickerViewController {
        let documentPickerController: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            documentPickerController = UIDocumentPickerViewController(supportedFilenameExtensions: ["key", "keyx"])
        } else {
            documentPickerController = UIDocumentPickerViewController(
                documentTypes: ["com.df.passs.key", "com.df.passs.keyx"],
                in: .open
            )
        }
        return documentPickerController
    }
}
