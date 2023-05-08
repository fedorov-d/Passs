//
//  GenericContentTableViewCell.swift
//  Passs
//
//  Created by Dmitry on 08.05.2023.
//

import UIKit

final class GenericContentTableViewCell<Content: UIView>: UITableViewCell {
    lazy var customContentView = Content()

    var customContentInset: NSDirectionalEdgeInsets = .zero {
        didSet {
            customContentView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(customContentInset)
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(customContentView)
        customContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(customContentInset)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
