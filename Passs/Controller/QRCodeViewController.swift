//
//  QRCodeViewController.swift
//  Passs
//
//  Created by Dmitry on 15.04.2023.
//

import UIKit

final class QRCodeViewController: UIViewController {
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 40
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var qrCodeImageView = UIImageView()

    private let string: String
    private let qrCodeManager: QRCodeManager

    init(string: String, qrCodeManager: QRCodeManager) {
        self.string = string
        self.qrCodeManager = qrCodeManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    init() { fatalError() }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(40)
            make.width.equalTo(backgroundView.snp.height)
        }
        backgroundView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(30)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        qrCodeManager.generateQRCode(from: string,
                                     size: qrCodeImageView.bounds.size) { [qrCodeImageView] image in
            qrCodeImageView.image = image
        }
    }
}
