//
//  ApplicationViewController.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import MobileCoreServices
import UIKit

class ApplicationViewController: ViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    toolbarItems = [
      UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("didSelectAddBarButton:")),
      UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
      UIBarButtonItem(customView: segmentedControl),
      UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
      timerButton
    ]
  }

  // MARK: - 

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    displayImage = nil
    processedImage = nil
    timerButton.title = nil

    if let imageView = imageView as? ImageView {
      imageView.image = nil
    }

    dismissViewControllerAnimated(true) { [weak self] in
      let mediaType = info[UIImagePickerControllerMediaType] as? String

      guard mediaType == String(kUTTypeImage) else {
        return
      }

      guard let selectedImageProcessingFilter = self?.selectedImageProcessingFilter else {
        return
      }

      if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
        self?.displayImage = editedImage
      }
      else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
        self?.displayImage = originalImage
      }

      guard let displayImage = self?.displayImage else {
        return
      }

      switch selectedImageProcessingFilter {
      case .Metal:
        self?.applyFiltersAndDisplay(image: displayImage, filterClass: GoldenSpiralMetalFilter.self, viewClass: MetalImageView.self)
      case .CoreGraphics:
        self?.applyFiltersAndDisplay(image: displayImage, filterClass: GoldenSpiralCGFilter.self, viewClass: UIImageView.self)
      }
    }
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  // MARK: - Actions

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

  @IBAction func didSelectSaveBarButton(sender: UIBarButtonItem) {
    guard let processedImage = processedImage else {
      return
    }

    sender.enabled = false

    UIImageWriteToSavedPhotosAlbum(processedImage, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
  }

  // MARK: -

  @IBOutlet weak var saveBarButton: UIBarButtonItem!

  override func applyFiltersAndDisplay<T: GoldenSpiralFilter, V: ImageView where V: UIView>(image sourceImage: UIImage, filterClass: T.Type, viewClass: V.Type) {
    super.applyFiltersAndDisplay(image: sourceImage, filterClass: filterClass, viewClass: viewClass)
    if processedImage != nil {
      saveBarButton.enabled = true
    }
  }

  func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
    let title: String, message: String

    if error == nil {
      title = Localizable.Save.Success.Title
      message = Localizable.Save.Success.Message
    }
    else {
      title = Localizable.Save.Error.Title
      message = error?.localizedDescription ?? Localizable.Save.Error.Title
    }

    let actionTitle = Localizable.Button.OK
    let controller = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    controller.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
    presentViewController(controller, animated: true, completion: nil)
  }

}