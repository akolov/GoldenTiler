//
//  ViewController.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Metal
import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

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

  // MARK: -

  enum ImageProcessingFilter: Int {
    case Metal = 0
    case CoreGraphics = 1
  }

  lazy var segmentedControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Metal", "CoreGraphics"])
    control.selectedSegmentIndex = 0
    return control
  }()

  let timerButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!

  var selectedImageProcessingFilter: ImageProcessingFilter {
    return ImageProcessingFilter.init(rawValue: segmentedControl.selectedSegmentIndex)!
  }

  private var minimumImageZoomScale: CGFloat {
    guard let image = imageView.image else {
      return 1.0
    }

    return scrollView.bounds.width / image.size.width
  }

  func applyFiltersAndDisplay<T: GoldenSpiralFilter>(image sourceImage: UIImage, filterClass: T.Type) {
    let duration = Timer.run {
      var filter = filterClass.init()
      filter.inputImage = sourceImage.imageByFixingOrientation()

      imageView.image = filter.outputImage
    }

    if let duration = duration {
      timerButton.title = String(format: "%.2f ms", duration.milliseconds)
    }

    if let image = imageView.image {
      scrollView.minimumZoomScale = minimumImageZoomScale
      scrollView.zoomScale = scrollView.minimumZoomScale
      imageViewWidthConstraint.constant = image.size.width
      imageViewHeightConstraint.constant = image.size.height
    }
  }

  func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
    if error == nil {
      let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .Alert)
      ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
      presentViewController(ac, animated: true, completion: nil)
    }
    else {
      let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
      ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
      presentViewController(ac, animated: true, completion: nil)
    }
  }

}

