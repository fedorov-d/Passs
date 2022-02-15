//
//  TextFieldCell.swift
//  Passs
//
//  Created by Dmitry Fedorov on 15.02.2022.
//

import UIKit

class TextFieldCell: UITableViewCell {

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.delegate = self
        let font = UIFont.preferredFont(forTextStyle: .callout)
        textField.font = font
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textFieldTextDidChange(_:)), for: .editingChanged)
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.bottom.equalToSuperview().inset(2)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TextFieldCell {

    @objc func textFieldTextDidChange(_ sender: AnyObject) {

    }
}

extension TextFieldCell: UITextFieldDelegate {

}
