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
      UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("didSelectAddBarButton:"))
    ]
  }

  // MARK: - 

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    dismissViewControllerAnimated(true) { [weak self] in
      let mediaType = info[UIImagePickerControllerMediaType] as? String

      guard mediaType == String(kUTTypeImage) else {
        return
      }

      if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
        self?.applyFiltersAndDisplay(image: editedImage)
      }
      else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
        self?.applyFiltersAndDisplay(image: originalImage)
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
    guard let image = imageView.image?.imageByApplyingOrientation(4) else {
      return
    }

    guard let device = MTLCreateSystemDefaultDevice() else {
      return
    }

    sender.enabled = false

    let context = CIContext(MTLDevice: device)
    let imageToSave = UIImage(CGImage: context.createCGImage(image, fromRect: image.extent))
    UIImageWriteToSavedPhotosAlbum(imageToSave, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
  }

  // MARK: -

  @IBOutlet weak var saveBarButton: UIBarButtonItem!

  override func applyFiltersAndDisplay(image sourceImage: UIImage) {
    super.applyFiltersAndDisplay(image: sourceImage)
    if imageView.image != nil {
      saveBarButton.enabled = true
    }
  }

}