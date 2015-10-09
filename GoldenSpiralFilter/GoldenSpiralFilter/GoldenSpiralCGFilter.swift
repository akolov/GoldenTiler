//
//  GoldenSpiralCGFilter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreImage
import UIKit

public class GoldenSpiralCGFilter: NSObject, GoldenSpiralFilter {

  public required override init() {
    super.init()
  }

  public var inputImage: UIImage? {
    didSet {
      _outputImage = nil

      guard let inputImage = inputImage else {
        return
      }

      colorSpace = CGImageGetColorSpace(inputImage.CGImage) ?? CGColorSpaceCreateDeviceRGB()

      let dimension = round(min(inputImage.size.width, inputImage.size.height))
      if inputImage.size.height > inputImage.size.width {
        outputImageSize = CGSize(width: dimension, height: dimension * φ)
      }
      else {
        outputImageSize = CGSize(width: dimension * φ, height: dimension)
      }
    }
  }

  private(set) public var colorSpace: CGColorSpaceRef?
  private(set) public var outputImageSize: CGSize = CGSizeZero

  private var _outputImage: UIImage?
  public var outputImage: UIImage? {
    if _outputImage != nil {
      return _outputImage
    }

    guard let inputImage = inputImage else {
      return nil
    }

    _outputImage = tileImage(image: inputImage)
    return _outputImage
  }

  public var canProcessImage: Bool {
    return true
  }

  private(set) public lazy var context: CIContext = {
    return CIContext()
  }()

  private func tileImage(image sourceImage: UIImage) -> UIImage? {
    guard let image = imagedPreparedForTiling(image: sourceImage) else {
      return nil
    }

    // Tile images

    let bitmapContext = CGBitmapContextCreate(nil, Int(outputImageSize.width), Int(outputImageSize.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)

    CGContextSetInterpolationQuality(bitmapContext, .High)

    for tile in tiles() {
      CGContextDrawImage(bitmapContext, tile, image)
    }

    guard let cgImage = CGBitmapContextCreateImage(bitmapContext) else {
      return nil
    }

    return UIImage(CGImage: cgImage)
  }

  private func imagedPreparedForTiling(image sourceImage: UIImage) -> CGImageRef? {
    guard let image = sourceImage.imageByFixingOrientation()?.CGImage else {
      return nil
    }

    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    let dimension = min(width, height)

    let cropRect = imageCropRect(image: CIImage(CGImage: image), toDimension: CGFloat(dimension))
    return CGImageCreateWithImageInRect(image, cropRect)
  }

  // MARK: - Debugging support

  func debugQuickLookObject() -> AnyObject? {
    return nil
  }

}
