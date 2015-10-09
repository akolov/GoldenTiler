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
    guard let inputImage = inputImage else {
      return "GoldenSpiralMetalFilter with no images set"
    }

    let spacing: CGFloat = 30
    let portrait = inputImage.size.height > inputImage.size.width

    let inputAspectRatio = inputImage.size.width / inputImage.size.height
    let outputAspectRatio = outputImageSize.width / outputImageSize.height

    var inputRect = CGRectZero, outputRect = CGRectZero
    if portrait {
      inputRect.size.width = 400
      inputRect.size.height = round(inputRect.width / inputAspectRatio)
      outputRect.size.width = 400
      outputRect.size.height = round(outputRect.width / outputAspectRatio)
      inputRect.origin.y = (outputRect.size.height - inputRect.size.height) / 2.0
    }
    else {
      inputRect.size.height = 400
      inputRect.size.width = round(inputRect.height * inputAspectRatio)
      outputRect.size.height = 400
      outputRect.size.width = round(outputRect.height * outputAspectRatio)
    }

    outputRect.origin.x += inputRect.maxX + spacing

    let canvasRect = CGRectUnion(inputRect, outputRect)
    UIGraphicsBeginImageContextWithOptions(canvasRect.size, false, 0)
    inputImage.drawInRect(inputRect)

    if let _outputImage = _outputImage {
      _outputImage.drawInRect(outputRect)
    }
    else {
      var transform = CGAffineTransformIdentity
      transform = CGAffineTransformTranslate(transform, outputRect.origin.x, outputImageSize.height * outputRect.height / outputImageSize.height)
      transform = CGAffineTransformScale(transform, outputRect.width / outputImageSize.width, -outputRect.height / outputImageSize.height)

      var paths = [UIBezierPath]()
      for rect in tiles() {
        let path = UIBezierPath(rect: CGRectApplyAffineTransform(rect, transform))
        paths.append(path)
      }

      let colorShift = 0.7 / CGFloat(paths.count)
      for (index, path) in paths.enumerate() {
        UIColor(white: 0.2 + colorShift * CGFloat(index), alpha: 1).setFill()
        path.fill()
      }

      let string: NSString = "Output image has not been processed yet"
      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .Center
      paragraph.lineBreakMode = .ByWordWrapping
      let attributes = [NSParagraphStyleAttributeName: paragraph, NSForegroundColorAttributeName: UIColor.whiteColor()]
      let textBoxSize = outputRect.insetBy(dx: 10, dy: 10).size
      var textRect = string.boundingRectWithSize(textBoxSize, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
      textRect.origin.x = outputRect.minX + (outputRect.width - textRect.width) / 2.0
      textRect.origin.y = outputRect.minY + (outputRect.height - textRect.height) / 2.0
      string.drawInRect(textRect, withAttributes: attributes)
    }

    let arrow: NSString = "➡︎"
    var arrowRect = arrow.boundingRectWithSize(canvasRect.size, options: .UsesLineFragmentOrigin, attributes: nil, context: nil)
    arrowRect.origin.x = canvasRect.midX - arrowRect.midX
    arrowRect.origin.y = canvasRect.midY - arrowRect.midY
    arrow.drawInRect(arrowRect, withAttributes: nil)

    return UIGraphicsGetImageFromCurrentImageContext()
  }

}
