//
//  ColoredTableViewHeaderFooterView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 17.02.2022.
//

import UIKit

class ColoredTableViewHeaderFooterView: UITableViewHeaderFooterView {
    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(7.5)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(6.5)
            make.width.equalToSuperview().multipliedBy(0.75)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
