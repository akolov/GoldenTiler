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
    var rdar23011575Checker: Rdar23011575Checker?
    if selectedImageProcessingFilter == .Metal {
      rdar23011575Checker = Rdar23011575Checker()
      rdar23011575Checker!.delegate = self
      rdar23011575Checker!.start()
    }

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

      var outputImage: UIImage!

      let duration = Timer.run {
        switch selectedImageProcessingFilter {
        case .Metal:
          let filter = GoldenSpiralMetalFilter()
          filter.inputImage = sourceImage
          if filter.canProcessImage {
            outputImage = filter.outputImage?.imageByConvertingFromCIImage(device: filter.device, context: filter.context)
          }
          else {
            dispatch_async(dispatch_get_main_queue()) {
              self?.showCannotBeProcessedByMetalAlert()
            }
          }
        case .CoreGraphics:
          let filter = GoldenSpiralCGFilter()
          filter.inputImage = sourceImage
          outputImage = filter.outputImage
        }
      }

      rdar23011575Checker?.stop()

      if let duration = duration {
        let durationString = self?.timerFormatter.stringFromTimer(duration)
        Logger.log("Filter executed in \(durationString)")
      }

      guard outputImage != nil else {
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
