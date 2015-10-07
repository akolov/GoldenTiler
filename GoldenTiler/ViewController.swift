//
//  ViewController.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Metal
import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, Rdar23011575CheckerProtocol {

  // MARK: UIContentContainer

  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    coordinator.animateAlongsideTransition({ context in
      self.scrollView.minimumZoomScale = self.minimumImageZoomScale
      self.scrollView.zoomScale = min(self.scrollView.zoomScale, self.scrollView.minimumZoomScale)
    }, completion: nil)
  }

  // MARK: UITraitEnvironment

  override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    scrollView.minimumZoomScale = minimumImageZoomScale
    scrollView.zoomScale = min(scrollView.zoomScale, scrollView.minimumZoomScale)
  }

  // MARK: -

  // MARK: UIScrollViewDelegate

  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageView
  }

  // MARK: Rdar23011575CheckerProtocol

  func rdar23011575Checker(checker: Rdar23011575Checker, didHitThresholdValue threshold: NSTimeInterval) {
    let actionTitle = Localizable.Button.OK
    let controller = UIAlertController(title: "Oh no!", message: "Looks like you've hit a bug described in rdar://23011575. Please restart the app or extension and try again. Alternatively use GoreGraphics processing.", preferredStyle: .Alert)
    controller.addAction(UIAlertAction(title: actionTitle, style: .Cancel, handler: nil))
    controller.addAction(UIAlertAction(title: "Copy", style: UIAlertActionStyle.Default) { action in
      UIPasteboard.generalPasteboard().string = "rdar://23011575"
    })
    presentViewController(controller, animated: true, completion: nil)
  }

  // MARK: - Actions

  func segmentedControlDidChangeValue(sender: UISegmentedControl) {
    guard let displayImage = displayImage else {
      return
    }

    switch selectedImageProcessingFilter {
    case .Metal:
      applyFiltersAndDisplay(image: displayImage, filterClass: GoldenSpiralMetalFilter.self, viewClass: MetalImageView.self)
    case .CoreGraphics:
      applyFiltersAndDisplay(image: displayImage, filterClass: GoldenSpiralCGFilter.self, viewClass: UIImageView.self)
    }
  }

  // MARK: -

  enum ImageProcessingFilter: Int {
    case Metal = 0
    case CoreGraphics = 1
  }

  lazy var segmentedControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Metal", "CoreGraphics"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: Selector("segmentedControlDidChangeValue:"), forControlEvents: .ValueChanged)
    return control
  }()

  let timerButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var busyView: BusyView!

  var imageView: UIView?
  var displayImage: UIImage?
  var processedImage: UIImage?

  var selectedImageProcessingFilter: ImageProcessingFilter {
    return ImageProcessingFilter.init(rawValue: segmentedControl.selectedSegmentIndex)!
  }

  private var minimumImageZoomScale: CGFloat {
    guard let imageView = imageView as? ImageView else {
      return 1.0
    }

    guard let image = imageView.image else {
      return 1.0
    }

    return scrollView.bounds.width / image.size.width
  }

  private lazy var timerFormatter: TimerFormatter = {
    return TimerFormatter()
  }()

  func toggleInterface(enabled enabled: Bool) {
    busyView.hidden = enabled
    scrollView.userInteractionEnabled = enabled

    navigationItem.rightBarButtonItem?.enabled = enabled

    if let toolbarItems = toolbarItems {
      for item in toolbarItems {
        item.enabled = enabled
      }
    }
  }

  func showCannotBeProcessedByMetalAlert() {
    let actionTitle = Localizable.Button.OK
    let controller = UIAlertController(title: Localizable.MetalError.Title, message: Localizable.MetalError.Message, preferredStyle: .Alert)
    controller.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
    presentViewController(controller, animated: true, completion: nil)
  }

  func applyFiltersAndDisplay<T: GoldenSpiralFilter, V: ImageView where V: UIView>(image sourceImage: UIImage, filterClass: T.Type, viewClass: V.Type) {
    toggleInterface(enabled: false)

    let rdar23011575Checker = Rdar23011575Checker()
    rdar23011575Checker.delegate = self
    rdar23011575Checker.start()

    dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) { [weak self] in
      let duration = Timer.run {
        var filter = filterClass.init()
        filter.inputImage = sourceImage.imageByFixingOrientation()
        if filter.canProcessImage {
          self?.processedImage = filter.outputImage
        }
        else {
          dispatch_async(dispatch_get_main_queue()) {
            self?.showCannotBeProcessedByMetalAlert()
          }
        }
      }

      rdar23011575Checker.stop()

      dispatch_async(dispatch_get_main_queue()) {
        self?.toggleInterface(enabled: true)

        guard let scrollView = self?.scrollView else {
          return
        }

        guard let processedImage = self?.processedImage else {
          return
        }

        let myView: V
        if let aView = self?.imageView as? V {
          myView = aView
        }
        else {
          self?.imageView?.removeFromSuperview()
          myView = viewClass.init()
          myView.translatesAutoresizingMaskIntoConstraints = false
          scrollView.addSubview(myView)
          self?.imageView = myView

          var constraints = [NSLayoutConstraint]()
          constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[myView(width)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: ["width": processedImage.size.width], views: ["myView": myView])
          constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[myView(height)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: ["height": processedImage.size.height], views: ["myView": myView])
          scrollView.addConstraints(constraints)
        }

        myView.image = processedImage
        scrollView.minimumZoomScale = self?.minimumImageZoomScale ?? 1.0
        scrollView.zoomScale = scrollView.minimumZoomScale

        if let duration = duration {
          self?.timerButton.title = self?.timerFormatter.stringFromTimer(duration, unit: .Millisecond)
        }
      }
    }
  }

}

