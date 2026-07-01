//
//  CompanyLogoView.swift
//  letsApply
//

import UIKit

final class CompanyLogoView: UIView {

    private static let imageCache = NSCache<NSURL, UIImage>()

    private var imageTask: URLSessionDataTask?
    private var representedURL: URL?

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        showFallback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageTask?.cancel()
    }

    func configure(with job: Job) {
        reset()
        accessibilityLabel = "\(job.companyName) logo"

        if let imageName = job.companyImageName,
           !imageName.isEmpty,
           let image = UIImage(named: imageName) {
            showLogo(image)
            return
        }

        guard let logoURLText = job.companyLogoURL?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              let logoURL = URL(string: logoURLText),
              logoURL.scheme?.lowercased() == "https" else {
            showFallback()
            return
        }

        representedURL = logoURL
        if let cachedImage = Self.imageCache.object(forKey: logoURL as NSURL) {
            showLogo(cachedImage)
            return
        }

        showFallback()
        var request = URLRequest(url: logoURL)
        request.timeoutInterval = 12
        request.cachePolicy = .returnCacheDataElseLoad

        imageTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self,
                  self.representedURL == logoURL,
                  let data,
                  data.count <= 2_000_000,
                  let image = UIImage(data: data) else {
                return
            }

            if let mimeType = response?.mimeType,
               !mimeType.lowercased().hasPrefix("image/") {
                return
            }

            Self.imageCache.setObject(image, forKey: logoURL as NSURL)
            DispatchQueue.main.async {
                guard self.representedURL == logoURL else { return }
                self.showLogo(image)
            }
        }
        imageTask?.resume()
    }

    func reset() {
        imageTask?.cancel()
        imageTask = nil
        representedURL = nil
        showFallback()
    }

    private func setupUI() {
        backgroundColor = AppTheme.mutedSurface
        layer.cornerRadius = AppTheme.cardRadius
        layer.borderWidth = 1
        layer.borderColor = AppTheme.border.cgColor
        clipsToBounds = true
        isAccessibilityElement = true

        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    private func showFallback() {
        backgroundColor = AppTheme.mutedSurface
        imageView.image = UIImage(systemName: "briefcase.fill")
        imageView.tintColor = AppTheme.brand
    }

    private func showLogo(_ image: UIImage) {
        backgroundColor = AppTheme.surface
        imageView.image = image
        imageView.tintColor = nil
    }
}
