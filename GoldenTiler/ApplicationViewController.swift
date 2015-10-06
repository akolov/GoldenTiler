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
    imageView.image = nil
    timerButton.title = nil

    dismissViewControllerAnimated(true) { [weak self] in
      let mediaType = info[UIImagePickerControllerMediaType] as? String

      guard mediaType == String(kUTTypeImage) else {
        return
      }

      guard let selectedImageProcessingFilter = self?.selectedImageProcessingFilter else {
        return
      }

      let imageToEdit: UIImage!

      if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
        imageToEdit = editedImage
      }
      else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
        imageToEdit = originalImage
      }
      else {
        return
      }

      switch selectedImageProcessingFilter {
      case .Metal:
        self?.applyFiltersAndDisplay(image: imageToEdit, filterClass: GoldenSpiralMetalFilter.self)
      case .CoreGraphics:
        self?.applyFiltersAndDisplay(image: imageToEdit, filterClass: GoldenSpiralCGFilter.self)
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
    guard let image = imageView.image else {
      return
    }

    sender.enabled = false

    UIImageWriteToSavedPhotosAlbum(image, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
  }

  // MARK: -

  @IBOutlet weak var saveBarButton: UIBarButtonItem!

  override func applyFiltersAndDisplay<T: GoldenSpiralFilter>(image sourceImage: UIImage, filterClass: T.Type) {
    super.applyFiltersAndDisplay(image: sourceImage, filterClass: filterClass)
    if imageView.image != nil {
      saveBarButton.enabled = true
    }
  }

}