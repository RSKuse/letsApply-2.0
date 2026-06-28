//
//  AdvertContainerView.swift
//  letsApply
//

import UIKit

class AdvertContainerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let insights: [CareerInsight] = [
        CareerInsight(
            category: "Application intelligence",
            title: "One profile. Better applications.",
            detail: "Let’s Apply prepares the right route, documents, and next step for every vacancy.",
            systemImageName: "wand.and.stars",
            style: .ink
        ),
        CareerInsight(
            category: "Interview signal",
            title: "Pause before you answer.",
            detail: "A calm two-second pause reads as thoughtful, not uncertain.",
            systemImageName: "person.wave.2.fill",
            style: .green
        ),
        CareerInsight(
            category: "Did you know?",
            title: "Achievements beat task lists.",
            detail: "Show what improved, changed, grew, or became faster because of your work.",
            systemImageName: "chart.line.uptrend.xyaxis",
            style: .warm
        ),
        CareerInsight(
            category: "CV clinic",
            title: "Match the role, not the buzzwords.",
            detail: "Use evidence from your real experience. Never add a skill you cannot defend in an interview.",
            systemImageName: "doc.text.magnifyingglass",
            style: .ocean
        ),
        CareerInsight(
            category: "Career momentum",
            title: "A rejection is data, not a verdict.",
            detail: "Review the match, improve the evidence, and make the next application sharper.",
            systemImageName: "arrow.trianglehead.2.clockwise.rotate.90",
            style: .ink
        ),
        CareerInsight(
            category: "Interview presence",
            title: "Your posture speaks first.",
            detail: "Sit comfortably upright, keep your shoulders relaxed, and look at the person asking the question.",
            systemImageName: "figure.stand",
            style: .green
        ),
        CareerInsight(
            category: "Cover letter fact",
            title: "Specific beats dramatic.",
            detail: "Connect one genuine strength to the employer’s need instead of making broad claims.",
            systemImageName: "text.document.fill",
            style: .warm
        ),
        CareerInsight(
            category: "Work-life humour",
            title: "“Entry level” should not mean ten years.",
            detail: "Until job adverts learn maths, we’ll keep helping you identify the evidence that really counts.",
            systemImageName: "face.smiling.inverse",
            style: .ocean
        ),
        CareerInsight(
            category: "Application safety",
            title: "You approve every submission.",
            detail: "Let’s Apply prepares the work. Nothing is emailed or submitted without your final review.",
            systemImageName: "checkmark.shield.fill",
            style: .ink
        ),
        CareerInsight(
            category: "Starting something",
            title: "Employment is one path. Building is another.",
            detail: "Your skills can solve problems for an employer, a client, or a business of your own.",
            systemImageName: "lightbulb.max.fill",
            style: .green
        )
    ]

    private var rotationTimer: Timer?
    private var currentIndex = 0

    private lazy var advertCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppTheme.background
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(AdvertCell.self, forCellWithReuseIdentifier: AdvertCell.reuseIdentifier)
        return collectionView
    }()

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = insights.count
        control.currentPage = 0
        control.currentPageIndicatorTintColor = AppTheme.brand
        control.pageIndicatorTintColor = AppTheme.border
        control.isUserInteractionEnabled = true
        control.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        rotationTimer?.invalidate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopRotation() : startRotation()
    }

    private func setupUI() {
        addSubview(advertCollectionView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            advertCollectionView.topAnchor.constraint(equalTo: topAnchor),
            advertCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            advertCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            advertCollectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -4),

            pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            pageControl.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func startRotation() {
        stopRotation()
        rotationTimer = Timer.scheduledTimer(
            timeInterval: 6,
            target: self,
            selector: #selector(showNextInsight),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    @objc private func showNextInsight() {
        guard !insights.isEmpty else { return }
        currentIndex = (currentIndex + 1) % insights.count
        pageControl.currentPage = currentIndex
        advertCollectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    @objc private func pageControlChanged() {
        currentIndex = pageControl.currentPage
        advertCollectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        startRotation()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return insights.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AdvertCell.reuseIdentifier,
            for: indexPath
        ) as! AdvertCell
        cell.configure(with: insights[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showNextInsight()
        startRotation()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: bounds.width, height: collectionView.bounds.height)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopRotation()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
        startRotation()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        guard advertCollectionView.bounds.width > 0 else { return }
        let page = Int(round(
            advertCollectionView.contentOffset.x / advertCollectionView.bounds.width
        ))
        currentIndex = min(max(page, 0), insights.count - 1)
        pageControl.currentPage = currentIndex
    }
}
