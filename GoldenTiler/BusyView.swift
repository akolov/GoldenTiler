//
//  BusyView.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import UIKit

@IBDesignable
class BusyView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  override func updateConstraints() {
    super.updateConstraints()

    guard !didSetupConstraints else {
      return
    }

    visualEffectView.translatesAutoresizingMaskIntoConstraints = false

    var constraints = [NSLayoutConstraint]()
    constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[visualEffectView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["visualEffectView": visualEffectView])
    constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[visualEffectView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["visualEffectView": visualEffectView])
    addConstraints(constraints)

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false

    visualEffectView.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: visualEffectView, attribute: .CenterX, multiplier: 1.0, constant: 0))
    visualEffectView.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: visualEffectView, attribute: .CenterY, multiplier: 1.0, constant: 0))
  }

  override var hidden: Bool {
    didSet {
      if hidden {
        activityIndicator.stopAnimating()
      }
      else {
        activityIndicator.startAnimating()
      }
    }
  }

  // MARK: -

  private var didSetupConstraints: Bool = false

  private(set) lazy var activityIndicator: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView()
    view.activityIndicatorViewStyle = .WhiteLarge
    view.color = UIColor.darkGrayColor()
    return view
  }()

  private(set) var visualEffect: UIBlurEffect = UIBlurEffect(style: .Light)
  private(set) lazy var visualEffectView: UIVisualEffectView = {
    return UIVisualEffectView(effect: self.visualEffect)
  }()

  private func commonInit() {
    backgroundColor = UIColor.clearColor()
    opaque = false

    addSubview(visualEffectView)
    visualEffectView.addSubview(activityIndicator)

    layer.cornerRadius = 10
    layer.masksToBounds = true
  }

}
