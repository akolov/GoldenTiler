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
    guard let inputImage = inputImage else {
      return nil
    }

    return tileImage(image: inputImage)
  }

  var canProcessImage: Bool {
    return true
  }

  private(set) lazy var context: CIContext = {
    return CIContext()
  }()

  private func tileImage(image sourceImage: UIImage) -> UIImage? {
    guard let (image, portrait) = imagedPreparedForTiling(image: sourceImage) else {
      return nil
    }

    // Tile images

    let bitmapContext: CGContextRef?

    var transform = CGAffineTransformIdentity

    if portrait {
      bitmapContext = CGBitmapContextCreate(nil, Int(outputImageSize.height), Int(outputImageSize.width), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)

      transform = CGAffineTransformTranslate(transform, 0, outputImageSize.height)
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))

      transform = CGAffineTransformTranslate(transform, outputImageSize.height, 0)
      transform = CGAffineTransformScale(transform, -1, 1)

      transform = CGAffineTransformTranslate(transform, outputImageSize.width, outputImageSize.height)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
    }
    else {
      bitmapContext = CGBitmapContextCreate(nil, Int(outputImageSize.width), Int(outputImageSize.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)

      transform = CGAffineTransformTranslate(transform, 0, outputImageSize.height)
      transform = CGAffineTransformScale(transform, 1, -1)
    }

    CGContextConcatCTM(bitmapContext, transform)
    CGContextSetInterpolationQuality(bitmapContext, .High)

    for tile in tiles() {
      CGContextDrawImage(bitmapContext, tile, image)
    }

    guard let cgImage = CGBitmapContextCreateImage(bitmapContext) else {
      return nil
    }

    return UIImage(CGImage: cgImage)
  }

  private func imagedPreparedForTiling(image sourceImage: UIImage) -> (image: CGImageRef, portrait: Bool)? {
    guard let image = sourceImage.imageByFixingOrientation()?.CGImage else {
      return nil
    }

    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    let dimension = min(width, height)

    let portrait = height > width
    let cropRect = imageCropRect(image: CIImage(CGImage: image), toDimension: CGFloat(dimension))

    let bitsPerComponent = CGImageGetBitsPerComponent(image)
    let bitmapInfo = CGImageGetBitmapInfo(image)
    let bitmapContext = CGBitmapContextCreate(nil, dimension, dimension, bitsPerComponent, 0, colorSpace, bitmapInfo.rawValue)
    var transform = CGAffineTransformIdentity

    if portrait {
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
      transform = CGAffineTransformTranslate(transform, -CGFloat(dimension), 0)
    }

    transform = CGAffineTransformTranslate(transform, 0, CGFloat(dimension))
    transform = CGAffineTransformScale(transform, 1, -1)

    CGContextConcatCTM(bitmapContext, transform)
    CGContextDrawImage(bitmapContext, CGRectMake(-cropRect.origin.x, -cropRect.origin.y, CGFloat(width), CGFloat(height)), image)

    guard let preparedImage = CGBitmapContextCreateImage(bitmapContext) else {
      return nil
    }

    return (preparedImage, portrait)
  }

}
