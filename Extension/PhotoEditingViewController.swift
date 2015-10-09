//
//  PhotoEditingViewController.swift
//  Extension
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import GoldenSpiralFilter
import Metal
import Photos
import PhotosUI
import UIKit

class PhotoEditingViewController: ViewController, PHContentEditingController {

  var input: PHContentEditingInput?

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.contentInset.top = topLayoutGuide.length
  }

  // MARK: - PHContentEditingController

  func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
    return false
  }

  func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
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
    return false
  }

  func cancelContentEditing() {
    // noop
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
