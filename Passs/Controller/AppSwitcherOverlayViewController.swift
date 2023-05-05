//
//  AppSwitcherOverlayViewController.swift
//  Passs
//
//  Created by Dmitry Fedorov on 05.05.2023.
//

import UIKit
import SnapKit

final class AppSwitcherOverlayViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.alpha = 0

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.addSubview(visualEffectView)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
