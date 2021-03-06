//
//  ClusterAnnotationView.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 04.02.2022.
//

import MapKit
import UIKit

final class ClusterAnnotationView: MKAnnotationView {
  private enum Constants {
    static let borderWidth: CGFloat = 3
    static let width: CGFloat = 60
    static let annotationSize: CGSize = .init(width: width, height: width)
    static let radius = width / 2
    static let labelColor: UIColor = .white
    static let labelFont: UIFont = UIFont.systemFont(ofSize: 15, weight: .bold)
    static let labelInsetValue: CGFloat = 3
  }

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.borderWidth = Constants.borderWidth
    imageView.clipsToBounds = true
    return imageView
  }()

  private let countView = UIView()

  private let countLabel: UILabel = {
    let label = UILabel()
    label.textColor = Constants.labelColor
    label.font = Constants.labelFont
    return label
  }()

  var coordinate: CLLocationCoordinate2D?

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    imageView.image = nil
    frame = CGRect(origin: .zero, size: Constants.annotationSize)
    imageView.layer.cornerRadius = Constants.radius
    addSubview(imageView)
    addSubview(countView)
    countView.addSubview(countLabel)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    imageView.frame = bounds
    conficureCountView()
  }

  override func prepareForDisplay() {
    super.prepareForDisplay()
    guard let cluster = annotation as? Cluster else { return }
    setColor(.from(year: cluster.photo.year))
    countLabel.text = "\(cluster.count)"
    coordinate = cluster.coordinate
    imageView.image = nil
    ImageFetcher.shared.fetchHighestQuality(
      filePath: cluster.photo.file,
      quality: .preview,
      completion: { [weak self] result in
        guard let self = self else { return }
        assert(Thread.isMainThread)
        switch result {
        case let .success(image): self.imageView.image = image
        case let .failure(error): print(error.localizedDescription)
        }
      }
    )
    setNeedsLayout()
  }

  private func setColor(_ color: UIColor) {
    imageView.layer.borderColor = color.cgColor
    imageView.backgroundColor = color
    countView.backgroundColor = color
  }

  private func conficureCountView() {
    let labelSize = countLabel.intrinsicContentSize
    let viewSize = CGSize(
      width: labelSize.width + Constants.labelInsetValue * 2,
      height: labelSize.height + Constants.labelInsetValue * 2
    )
    countView.isHidden = viewSize.width > frame.width
    if countView.isHidden { return }
    let origin = CGPoint(x: bounds.width - viewSize.width, y: bounds.height - viewSize.height)
    countView.frame = CGRect(origin: origin, size: viewSize)
    countLabel.frame = CGRect(
      origin: CGPoint(x: Constants.labelInsetValue, y: Constants.labelInsetValue),
      size: labelSize
    )
    countView.layer.cornerRadius = min(labelSize.height, labelSize.width) / 2
  }
}
