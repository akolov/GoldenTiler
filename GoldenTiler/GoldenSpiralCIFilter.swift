//
//  GoldenSpiralCIFilter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation
import CoreImage
import ImageIO

class GoldenSpiralCIFilter: CIFilter, GoldenSpiralFilter {

  override var outputImage: CIImage? {
    guard let inputImage = inputImage else {
      return nil
    }

    return tileImage(inputImage)
  }

  // MARK: -

  var steps = 16

  var inputImage: CIImage? {
    didSet {
      colorSpace = inputImage?.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    }
  }

  private var colorSpace: CGColorSpaceRef?

  func tileImage(image: CIImage) -> CIImage? {
    guard let colorSpace = colorSpace else {
      return nil
    }

    let context = CIContext()
    let dimension = min(image.extent.width, image.extent.height)

    guard let cropped = squareCropImage(image, toDimension: dimension) else {
      return nil
    }

    let φ: CGFloat = (1 + sqrt(5.0)) / 2.0

    
  }

}