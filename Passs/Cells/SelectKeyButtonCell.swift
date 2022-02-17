//
//  SelectKeyButtonCell.swift
//  Passs
//
//  Created by Dmitry Fedorov on 17.02.2022.
//

import UIKit

class SelectKeyButtonCell: UITableViewCell {

    var onButtonTap: (() -> Void)?

    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("Select key file", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.systemBlue.withAlphaComponent(0.7), for: .highlighted)
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

}

extension SelectKeyButtonCell {

    @objc
    private func buttonTapped(_ sender: UIButton) {
        onButtonTap?()
    }

}
