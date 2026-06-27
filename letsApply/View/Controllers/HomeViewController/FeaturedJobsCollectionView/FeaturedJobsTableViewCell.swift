//
//  FeaturedJobsTableViewCell.swift
//  letsApply
//


import UIKit

class FeaturedJobsTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let reuseIdentifier = "FeaturedJobsTableViewCellID"

    var featuredJobsArray: [Job] = [] {
        didSet {
            featuredJobsCollectionView.reloadData()
        }
    }

    var didSelectJob: ((Job) -> Void)?

    private lazy var featuredJobsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        collectionView.backgroundColor = AppTheme.background
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            FeaturedJobCollectionCell.self,
            forCellWithReuseIdentifier: FeaturedJobCollectionCell.reuseIdentifier
        )
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppTheme.background
        contentView.backgroundColor = AppTheme.background

        contentView.addSubview(featuredJobsCollectionView)

        featuredJobsCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        featuredJobsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        featuredJobsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        featuredJobsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return featuredJobsArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeaturedJobCollectionCell.reuseIdentifier,
            for: indexPath
        ) as! FeaturedJobCollectionCell

        cell.configure(with: featuredJobsArray[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectJob?(featuredJobsArray[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 172, height: 216)
    }
}
