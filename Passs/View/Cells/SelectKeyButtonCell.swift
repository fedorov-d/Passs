//
//  SelectKeyButtonCell.swift
//  Passs
//
//  Created by Dmitry Fedorov on 17.02.2022.
//

import UIKit

class SelectKeyButtonCell: UITableViewCell {
    var onButtonTap: (() -> Void)?
    var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitleColor(.keepCyan, for: .normal)
        button.setTitleColor(.keepCyan.withAlphaComponent(0.7), for: .highlighted)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.contentHorizontalAlignment = .leading
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTarget(_ target: Any?, action: Selector) {
        button.removeAllActions()
        button.addTarget(target, action: action, for: .touchUpInside)
    }
}

extension SelectKeyButtonCell {
    @objc
    private func buttonTapped(_ sender: UIButton) {
        onButtonTap?()
    }
}
