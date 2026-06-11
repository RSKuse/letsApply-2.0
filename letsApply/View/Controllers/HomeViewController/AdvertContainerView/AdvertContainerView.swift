//
//  AdvertContainerView.swift
//  letsApply
//

import UIKit

class AdvertContainerView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private let imagePostCellHeight: CGFloat = 160

    lazy var advertImageCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        registerCollectionCells()
    }

    private func setupUI() {
        addSubview(advertImageCollectionView)

        NSLayoutConstraint.activate([
            advertImageCollectionView.rightAnchor.constraint(equalTo: rightAnchor),
            advertImageCollectionView.leftAnchor.constraint(equalTo: leftAnchor),
            advertImageCollectionView.topAnchor.constraint(equalTo: topAnchor),
            advertImageCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func registerCollectionCells() {
        advertImageCollectionView.register(AdvertCell.self, forCellWithReuseIdentifier: AdvertCell.reuseIdentifier)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AdvertCell.reuseIdentifier, for: indexPath) as! AdvertCell
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: bounds.width, height: imagePostCellHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
