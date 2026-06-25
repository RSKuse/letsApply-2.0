//
//  AdvertContainerView.swift
//  letsApply
//


import UIKit

class AdvertContainerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let banners = ["advert_banner"]

    private lazy var advertImageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(AdvertCell.self, forCellWithReuseIdentifier: AdvertCell.reuseIdentifier)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(advertImageCollectionView)

        advertImageCollectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        advertImageCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        advertImageCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        advertImageCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return banners.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: AdvertCell.reuseIdentifier,
            for: indexPath
        ) as! AdvertCell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: bounds.width, height: bounds.height)
    }
}
