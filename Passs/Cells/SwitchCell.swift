//
//  SwitchCell.swift
//  Passs
//
//  Created by Dmitry Fedorov on 16.02.2022.
//

import UIKit

class SwitchCell: UITableViewCell {
    var onSwitchValueChanged: ((_: Bool) -> Void)?

    var isEnabled: Bool {
        get {
            `switch`.isEnabled
        } set {
            `switch`.isEnabled = newValue
        }
    }

    var isOn: Bool {
        get {
            `switch`.isOn
        } set {
            `switch`.isOn = newValue
        }
    }

    private lazy var `switch`: UISwitch = {
        let result = UISwitch()
        result.isEnabled = false
        result.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        return result
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryView = `switch`
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SwitchCell {
    @objc func switchValueChanged(_ sender: UISwitch) {
        onSwitchValueChanged?(sender.isOn)
    }
}
