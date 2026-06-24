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






/*import UIKit

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
}*/
