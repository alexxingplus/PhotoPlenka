//
//  CloseButton.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 07.03.2022.
//

import UIKit

enum RoundButtonType {
  case close
  case share
  case location
  case back
  case mode
  case download
  case favourites
}

final class RoundButton: SquishyButton {
  private enum Constants {
    static let tintColor: UIColor = .label
    static let blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial
    static let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
    static let icon: UIImage = .init(systemName: "xmark", withConfiguration: config)!
  }

  let blur = UIVisualEffectView(effect: UIBlurEffect(style: Constants.blurStyle))

  init(type: RoundButtonType) {
    super.init(frame: .zero)
    setTitle(nil, for: .normal)
    backgroundColor = .clear
    setImage(type.icon, for: .normal)
    tintColor = Constants.tintColor
    blur.isUserInteractionEnabled = false
    blur.layer.masksToBounds = true
    self.insertSubview(blur, at: 0)
    if let imageView = imageView {
      bringSubviewToFront(imageView)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    blur.frame = bounds
    blur.layer.cornerRadius = blur.frame.width / 2
  }
}

extension RoundButtonType {
  var icon: UIImage {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
    switch self {
    case .close:
      return UIImage(systemName: "xmark", withConfiguration: config)!
    case .share:
      return UIImage(systemName: "square.and.arrow.up", withConfiguration: config)!
    case .location:
      return UIImage(systemName: "location", withConfiguration: config)!
    case .back:
      return UIImage(systemName: "chevron.left", withConfiguration: config)!
    case .mode:
      return UIImage(systemName: "rectangle.grid.1x2", withConfiguration: config)!
    case .download:
      return UIImage(systemName: "arrow.down.to.line", withConfiguration: config)!
    case .favourites:
      return UIImage(systemName: "heart", withConfiguration: config)!
    }
  }
}
