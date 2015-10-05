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

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var imageView: MetalImageView!
  @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!

  private var minimumImageZoomScale: CGFloat {
    guard let image = imageView.image else {
      return 1.0
    }

    return scrollView.bounds.width / image.extent.width
  }

  func applyFiltersAndDisplay(image sourceImage: UIImage) {
    if let image = sourceImage.CIImageWithAppliedOrientation() {
      let filter = GoldenSpiralMetalFilter()

      if image.extent.height > image.extent.width {
        filter.inputImage = image.imageByApplyingOrientation(8)
        imageView.image = filter.outputImage?.imageByApplyingOrientation(7)
      }
      else {
        filter.inputImage = image.imageByApplyingOrientation(4)
        imageView.image = filter.outputImage
      }
    }

    if let image = imageView.image {
      scrollView.minimumZoomScale = minimumImageZoomScale
      scrollView.zoomScale = scrollView.minimumZoomScale
      imageViewWidthConstraint.constant = image.extent.width
      imageViewHeightConstraint.constant = image.extent.height
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

