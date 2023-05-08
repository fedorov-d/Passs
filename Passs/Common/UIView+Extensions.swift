//
//  UIView+Extensions.swift
//  Passs
//
//  Created by Dmitry on 01.05.2023.
//

import UIKit

extension UIView {
    func embeddedInContainerView(containerView: UIView = UIView(), withEdges edges: NSDirectionalEdgeInsets) -> UIView {
        containerView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(edges)
        }
        return containerView
    }

    func embeddedInContainerView(containerView: UIView = UIView(),
                                 alignedWithReadableContentGuide: Bool,
                                 withEdges edges: NSDirectionalEdgeInsets) -> UIView {
        containerView.addSubview(self)
        self.snp.makeConstraints { make in
            if alignedWithReadableContentGuide {
                make.edges.equalTo(containerView.readableContentGuide).inset(edges)
            } else {
                make.edges.equalToSuperview().inset(edges)
            }
        }
        return containerView
    }
}
