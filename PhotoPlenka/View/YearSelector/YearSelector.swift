//
//  YearSelector.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 07.02.2022.
//

import UIKit

protocol YearSelectorDelegate: AnyObject {
  func rangeDidChange(newRange: ClosedRange<Int>)
}

final class YearSelector: UIView {
  private enum Constants {
    static let lineHeight: CGFloat = 7
    static let lineRadius: CGFloat = lineHeight / 2
    static let horizontalLineInset: CGFloat = 33
    static let thumbWidth: CGFloat = 50
    // так как у нас значения thumbView берутся с границ, то мы возможные значения thumbView.x ограничиваем ещё на половину thumbWidth (изначально у нас thumbView.center.x = horizontalLineInset)
    static let valueInset: CGFloat = horizontalLineInset + thumbWidth / 2
    static let cornerRadius: CGFloat = 13

    static let startYear: Int = 1826
    static let endYear: Int = 2000
  }

  private let thumbs: [ThumbView] = [
    .init(value: 0, valueSide: .right),
    .init(value: 1, valueSide: .left),
  ]

  // MARK: - public values

  var yearRange: ClosedRange<Int> {
    let year1 = year(from: thumbs[0].value)
    let year2 = year(from: thumbs[1].value)
    guard year1 < year2 else { return year2...year1 }
    return year1...year2
  }

  var valueRange: ClosedRange<CGFloat> {
    thumbs[0].value...thumbs[1].value
  }

  weak var delegate: YearSelectorDelegate?

  // MARK: - views

  private lazy var line: UIView = {
    let view = UIView()
    view.layer.insertSublayer(gradientLayer, at: 0)
    view.layer.cornerRadius = Constants.lineRadius
    view.clipsToBounds = true
    return view
  }()

  // shadows - серые линии вместо градиента за пределами выбранного отрезка
  private let leftLineShadow: UIView = {
    let view = UIView()
    view.backgroundColor = .yearLineShadowColor
    view.layer.cornerRadius = Constants.lineRadius
    return view
  }()

  private let rightLineShadow: UIView = {
    let view = UIView()
    view.backgroundColor = .yearLineShadowColor
    view.layer.cornerRadius = Constants.lineRadius
    return view
  }()

  private let gradientLayer = CAGradientLayer.yearGradient()
  private var panRecognizers = [UIPanGestureRecognizer]()

  init() {
    super.init(frame: .zero)
    backgroundColor = .systemBackground
    layer.cornerRadius = Constants.cornerRadius

    addSubview(line)
    addSubview(leftLineShadow)
    addSubview(rightLineShadow)

    for thumb in thumbs {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(dragThumb(_:)))
      panRecognizers.append(pan)
      thumb.isUserInteractionEnabled = true
      thumb.addGestureRecognizer(pan)
      addSubview(thumb)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let lineOrigin = CGPoint(
      x: Constants.horizontalLineInset,
      y: bounds.midY - Constants.lineHeight / 2
    )
    line.frame = CGRect(
      origin: lineOrigin,
      size: CGSize(
        width: bounds.width - Constants.horizontalLineInset * 2,
        height: Constants.lineHeight
      )
    )
    gradientLayer.frame = line.bounds

    updateThumbCoordinates()
    updateShadows()
  }

  @objc func dragThumb(_ sender: UIPanGestureRecognizer) {
    guard let thumb = sender.view as? ThumbView else { return }
    let translation = sender.translation(in: self)
    move(thumb: thumb, xDiff: translation.x)
    sender.setTranslation(.zero, in: self)
  }

  private func move(thumb: ThumbView, xDiff: CGFloat) {
    var newX = thumb.x + xDiff
    var newValue = value(from: newX)

    // ограничение на перемещение thumbView
    if newValue > 1 { newValue = 1; newX = x(from: newValue) }
    if newValue < 0 { newValue = 0; newX = x(from: newValue) }

    // обработка столкновений: thumb'ы не должны пересекаться
    // и если мы их сталкиваем, то они должны двигаться - прикольно
    switch thumb.valueSide {
    case .left:
      let leftThumb = thumbs[0]
      if leftThumb.value > newValue {
        move(thumb: leftThumb, xDiff: thumb.x - leftThumb.x)
      }
    case .right:
      let rightThumb = thumbs[1]
      if rightThumb.value < newValue {
        move(thumb: rightThumb, xDiff: thumb.x - rightThumb.x)
      }
    case .center: break
    }

    // получив новые значения, применяем их на thumb
    thumb.updateYear(year(from: newValue))
    thumb.x = newX
    thumb.value = newValue
    rangeDidChange()
  }

  private func rangeDidChange() {
    delegate?.rangeDidChange(newRange: yearRange)
    updateShadows()
  }

  // ставит thumbs в нужные места в зависимости от выставленных значений
  private func updateThumbCoordinates() {
    for thumb in thumbs {
      thumb.center.y = line.center.y
      thumb.x = x(from: thumb.value)
      thumb.updateYear(year(from: thumb.value))
    }
  }

  private func updateShadows() {
    let leftOriginX = Constants.horizontalLineInset
    let rightOriginX = thumbs[1].center.x
    let originY = bounds.midY - Constants.lineHeight / 2
    let height = Constants.lineHeight

    // левая тень - от начала линии до первого (левого) thumb
    let leftShadowWidth = thumbs[0].center.x - leftOriginX
    let leftOrigin = CGPoint(x: leftOriginX, y: originY)
    leftLineShadow.frame = CGRect(
      origin: leftOrigin,
      size: CGSize(width: leftShadowWidth, height: height)
    )

    // правая тень - от второго (правого) thumb
    let rightShadowWidth = bounds.width - Constants.horizontalLineInset - rightOriginX
    let rightOrigin = CGPoint(x: rightOriginX, y: originY)
    rightLineShadow.frame = CGRect(
      origin: rightOrigin,
      size: CGSize(width: rightShadowWidth, height: height)
    )
  }

  // MARK: - converting funcs

  // value - относительное расположение thumbView - от 0 до 1
  // так как у нас значения берутся с краёв, а не с середин, мы берём valueInset
  // value = x внутри отрезка возможных значений, разделённый на длину этого отрезка
  private func value(from x: CGFloat) -> CGFloat {
    let minX = Constants.valueInset
    let maxX = bounds.width - Constants.valueInset
    return (x - minX) / (maxX - minX)
  }

  // ищем координату thumbView исходя из value
  private func x(from value: CGFloat) -> CGFloat {
    let minX = Constants.valueInset
    let maxX = bounds.width - Constants.valueInset
    return minX + (maxX - minX) * value
  }

  private func year(from value: CGFloat) -> Int {
    Constants.startYear + Int(CGFloat(Constants.endYear - Constants.startYear) * value)
  }
}
