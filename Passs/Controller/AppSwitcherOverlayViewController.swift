//
//  AppSwitcherOverlayViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 05.05.2023.
//

import UIKit
import SnapKit

final class AppSwitcherOverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        addSubview(visualEffectView)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
