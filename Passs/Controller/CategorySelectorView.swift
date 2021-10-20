//
//  CategorySelectorView.swift
//  Passs
//
//  Created by Dmitry Fedorov on 09.04.2021.
//

import UIKit
import SnapKit

@objc class IntWrapper: NSObject {
    let i: Int
    init(int: Int) {
        i = int
    }
}

class CategorySelectorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var categories: [String] = [] {
        didSet {
            collectionView.reloadData()
            if categories.count > 0 {
                collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
            }
        }
    }
    
    var onSelect: ((Int) -> ())?
    
    @objc func willBeginDisplayCategory(at index: IntWrapper) {
        let indexPath = IndexPath(item: index.i, section: 0)
        selectCell(at: indexPath)
    }
    
    @objc func willEndDisplayCategory(at index: IntWrapper) {
        let indexPath = IndexPath(item: index.i + 1, section: 0)
        selectCell(at: indexPath)
    }
    
    private func selectCell(at indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isSelected = true
    }
    
    private let cellId = "cellId"
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20.0, bottom: 0, right: 20.0)
        layout.minimumInteritemSpacing = 10
        let colletionView = UICollectionView(frame: .zero,
                                             collectionViewLayout: layout)
        colletionView.alwaysBounceVertical = false
        colletionView.alwaysBounceHorizontal = true
        colletionView.showsHorizontalScrollIndicator = false
        colletionView.dataSource = self
        colletionView.delegate = self
        colletionView.register(CategoryItemView.self,
                               forCellWithReuseIdentifier: cellId)
        return colletionView
    }()
}

extension CategorySelectorView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let category = categories[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? CategoryItemView {
            cell.setTitle(category)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let indPath = collectionView.indexPathsForSelectedItems?.first else { return }
        cell.isSelected = indPath.item == indexPath.item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = NSAttributedString(string: self.categories[indexPath.item],
                                       attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        return CGSize(width: title.boundingRect(with: CGSize(width: Int.max, height: 40),
                                                options: .usesLineFragmentOrigin,
                                                context: nil).size.width + 20,
                      height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)
        if let cell = collectionView.cellForItem(at: indexPath) {
            let rect = convert(cell.frame, from: collectionView)
            if rect.minX < 0 {
                collectionView.scrollToItem(at: indexPath,
                                            at: .left,
                                            animated: true)
            } else if (rect.maxX > bounds.maxX) {
                collectionView.scrollToItem(at: indexPath,
                                            at: .right,
                                            animated: true)
            }
        }
    }
}

private extension CategorySelectorView {
    class CategoryItemView: UICollectionViewCell {
        
        private lazy var button: UIButton = {
            let button = UIButton()
            button.layer.cornerRadius = 10.0;
            button.isUserInteractionEnabled = false;
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            return button
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(button)
            button.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(5.0)
                make.bottom.equalToSuperview().offset(-2.0)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var isSelected: Bool {
            didSet {
                if (isSelected) {
                    button.backgroundColor = .black
                    button.setTitleColor(.white, for: .normal)
                    button.layer.borderWidth = 0
                    button.layer.borderColor = UIColor.black.cgColor
                } else {
                    button.backgroundColor = .white
                    button.setTitleColor(.black, for: .normal)
                    button.layer.borderWidth = 1.0
                    button.layer.borderColor = UIColor.lightGray.cgColor
                }
            }
        }
        
        func setTitle(_ title: String)  {
            button.setTitle(title, for: .normal)
        }
        
    }
}
