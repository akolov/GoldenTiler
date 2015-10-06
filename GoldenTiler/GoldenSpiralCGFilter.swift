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

class GoldenSpiralCGFilter: GoldenSpiralFilter {

  required init() {
    // noop
  }

  var inputImage: UIImage? {
    didSet {
      guard let inputImage = inputImage else {
        return
      }

      colorSpace = CGImageGetColorSpace(inputImage.CGImage) ?? CGColorSpaceCreateDeviceRGB()

      let dimension = ceil(min(inputImage.size.width, inputImage.size.height))
      outputImageSize = CGSize(width: dimension * φ, height: dimension)
    }
  }

  var colorSpace: CGColorSpaceRef?
  private(set) var outputImageSize: CGSize = CGSizeZero

  var outputImage: UIImage? {
    guard let sourceImage = inputImage?.CGImage else {
      return nil
    }

    guard let tiledImage = tileImage(sourceImage) else {
      return nil
    }

    return UIImage(CGImage: tiledImage)
  }

  var canProcessImage: Bool {
    return true
  }

  private(set) lazy var context: CIContext = {
    return CIContext()
  }()

  private func tileImage(image: CGImageRef) -> CGImageRef? {
    let width = CGFloat(CGImageGetWidth(image))
    let height = CGFloat(CGImageGetHeight(image))
    let dimension = ceil(min(width, height))
    let cropRect = imageCropRect(image: image, toDimension: dimension)

    guard let cropped = CGImageCreateWithImageInRect(image, cropRect) else {
      return nil
    }

    let flipped = imageByFixingOrientation(image: cropped)

    // Tile images

    let bitmapContext = CGBitmapContextCreate(nil, Int(outputImageSize.width), Int(outputImageSize.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
    let transform = CGAffineTransformMake(1, 0, 0, -1, 0, outputImageSize.height)
    CGContextConcatCTM(bitmapContext, transform)
    CGContextSetInterpolationQuality(bitmapContext, .High)

    for tile in tiles() {
      CGContextDrawImage(bitmapContext, tile, flipped)
    }

    return CGBitmapContextCreateImage(bitmapContext)
  }

}
