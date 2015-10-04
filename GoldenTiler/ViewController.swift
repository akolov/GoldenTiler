//
//  ViewController.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import MobileCoreServices
import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    toolbarItems = [
      UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("didSelectAddBarButton:"))
    ]
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: Actions

  func didSelectAddBarButton(sender: UIBarButtonItem) {
    let sourceType = UIImagePickerControllerSourceType.PhotoLibrary

    guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
      return
    }

    let picker = UIImagePickerController()
    picker.sourceType = sourceType
    picker.mediaTypes = [String(kUTTypeImage)]
    picker.allowsEditing = false
    picker.delegate = self

    presentViewController(picker, animated: true, completion: nil)
  }

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

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let mediaType = info[UIImagePickerControllerMediaType] as? String

    guard mediaType == String(kUTTypeImage) else {
      return
    }

    var image: CIImage?

    if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
      image = CIImage(image: editedImage)
    }
    else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      image = CIImage(image: originalImage)
    }

    if let image = image {
      let filter = GoldenSpiralFilter()
      filter.inputImage = image
      imageView.image = filter.outputImage
    }

    if let image = imageView.image {
      scrollView.minimumZoomScale = minimumImageZoomScale
      scrollView.zoomScale = scrollView.minimumZoomScale
      imageViewWidthConstraint.constant = image.extent.width
      imageViewHeightConstraint.constant = image.extent.height
    }

    dismissViewControllerAnimated(true, completion: nil)
  }

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

}

