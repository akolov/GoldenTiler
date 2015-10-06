//
//  PhotoEditingViewController.swift
//  Extension
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Metal
import Photos
import PhotosUI
import UIKit

class PhotoEditingViewController: ViewController, PHContentEditingController {

  var input: PHContentEditingInput?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.contentInset.top = topLayoutGuide.length
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - PHContentEditingController

  func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
    // Inspect the adjustmentData to determine whether your extension can work with past edits.
    // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
    return false
  }

  func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
    // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
    // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
    // If you returned false, the contentEditingInput has past edits "baked in".
    input = contentEditingInput

    guard let image = input?.displaySizeImage else {
      return
    }

    displayImage = image

    switch selectedImageProcessingFilter {
    case .Metal:
      applyFiltersAndDisplay(image: image, filterClass: GoldenSpiralMetalFilter.self, viewClass: MetalImageView.self)
    case .CoreGraphics:
      applyFiltersAndDisplay(image: image, filterClass: GoldenSpiralCGFilter.self, viewClass: UIImageView.self)
    }
  }

  func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
    // Update UI to reflect that editing has finished and output is being rendered.

    dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) { [weak self] in
      guard let input = self?.input else {
        completionHandler?(nil)
        return
      }

      let output = PHContentEditingOutput(contentEditingInput: input)

      guard let path = self?.input?.fullSizeImageURL?.path else {
        completionHandler?(output)
        return
      }

      guard let sourceImage = UIImage(contentsOfFile: path) else {
        completionHandler?(output)
        return
      }

      guard let selectedImageProcessingFilter = self?.selectedImageProcessingFilter else {
        completionHandler?(output)
        return
      }

      let filter: GoldenSpiralFilter

      switch selectedImageProcessingFilter {
      case .Metal:
        filter = GoldenSpiralMetalFilter()
      case .CoreGraphics:
        filter = GoldenSpiralCGFilter()
      }

      filter.inputImage = sourceImage

      guard let outputImage = filter.outputImage else {
        completionHandler?(output)
        return
      }

      if let renderedJPEGData = UIImageJPEGRepresentation(outputImage, 0.9) {
        renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
      }

      let adjustments = ["GoldenSpiralMetalFilterApplied": true]
      let data = NSKeyedArchiver.archivedDataWithRootObject(adjustments)
      let adjustmentData = PHAdjustmentData(formatIdentifier: "com.alexkolov.GoldenTiler", formatVersion: "1.0", data: data)
      output.adjustmentData = adjustmentData

      completionHandler?(output)
    }
  }

  var shouldShowCancelConfirmation: Bool {
    // Determines whether a confirmation to discard changes should be shown to the user on cancel.
    // (Typically, this should be "true" if there are any unsaved changes.)
    return false
  }

  func cancelContentEditing() {
    // Clean up temporary files, etc.
    // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
  }

  // MARK: -

  @IBOutlet weak var toolbar: UIToolbar! {
    didSet {
      toolbarItems = [
        UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
        UIBarButtonItem(customView: segmentedControl),
        UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
        timerButton
      ]

      toolbar.items = toolbarItems
    }
  }

}