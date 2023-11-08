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

        let imageView = UIImageView(image: UIImage(named: "lock"))
        imageView.contentMode = .scaleAspectFit

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurredEffectView)

        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

        vibrancyEffectView.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(80)
            make.centerY.equalToSuperview()
        }

        blurredEffectView.contentView.addSubview(vibrancyEffectView)
        vibrancyEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurredEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
