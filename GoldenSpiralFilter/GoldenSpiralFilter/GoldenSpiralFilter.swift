//
//  GoldenSpiralFilter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation
import ImageIO
import UIKit

let φ: CGFloat = (1 + sqrt(5.0)) / 2.0

public protocol GoldenSpiralFilter: NSObjectProtocol {

  init()

  var inputImage: UIImage? { get set }
  var colorSpace: CGColorSpaceRef? { get }
  var outputImage: UIImage? { get }
  var outputImageSize: CGSize { get }
  var canProcessImage: Bool { get }
  var context: CIContext { get }

  func tiles() -> AnyGenerator<CGRect>
  func imageCropRect(image sourceImage: CIImage, toDimension dimension: CGFloat) -> CGRect

}

public extension GoldenSpiralFilter {

  public func tiles() -> AnyGenerator<CGRect> {
    let dimension = min(outputImageSize.width, outputImageSize.height)
    let portrait = outputImageSize.height > outputImageSize.width
    var transform = CGAffineTransformIdentity

    // Transformations needed because context origin is (bottom, left)

    if portrait {
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
      transform = CGAffineTransformTranslate(transform, -outputImageSize.height, 0)
    }
    else {
      transform = CGAffineTransformTranslate(transform, 0, outputImageSize.height)
      transform = CGAffineTransformScale(transform, 1, -1)
    }

    var x: CGFloat = 0, y: CGFloat = 0, counter = 0

    return anyGenerator {
      let a = round(CGFloat(dimension) / pow(φ, CGFloat(counter)))
      let b = round(CGFloat(dimension) / pow(φ, CGFloat(counter) + 1))

      // Bail out when significant part is less than 2 pixels
      if a < 2 {
        return .None
      }

      var origin: CGPoint!

      switch counter % 4 {
      case 0:
        origin = CGPoint(x: x, y: y)
        x += round(a + b)

      case 1:
        origin = CGPoint(x: x - a, y: y)
        y += round(a + b)

      case 2:
        origin = CGPoint(x: x - a, y: y - a)
        x -= round(a + b)

      case 3:
        origin = CGPoint(x: x, y: y - a)
        y -= round(a + b)

      default:
        break
      }

      counter++

      let rect = CGRect(origin: origin, size: CGSize(width: a, height: a))
      return CGRectApplyAffineTransform(rect, transform)
    }
  }

  func imageCropRect(image sourceImage: CIImage, toDimension dimension: CGFloat) -> CGRect {
    let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    let orientation: AnyObject = sourceImage.properties[String(kCGImagePropertyOrientation)] ?? 1
    let features = detector.featuresInImage(sourceImage, options: [CIDetectorImageOrientation: orientation])

    let cropRect: CGRect
    if features.count == 0 {
      cropRect = CGRect(x: (sourceImage.extent.width - dimension) / 2.0, y: (sourceImage.extent.height - dimension) / 2.0, width: dimension, height: dimension)
    }
    else {
      // We've detected some faces, set crop rect to center around faces
      var facesRect = features.map { $0.bounds }.reduce(features.first!.bounds, combine: CGRectUnion)
      facesRect.insetInPlace(dx: (dimension - facesRect.width) / -2.0, dy: (dimension - facesRect.height) / -2.0)
      facesRect.offsetInPlace(dx: facesRect.minX < 0 ? -facesRect.minX : 0, dy: facesRect.minY < 0 ? -facesRect.minY : 0)
      facesRect.offsetInPlace(dx: dimension - facesRect.maxX, dy: dimension - facesRect.maxY)
      cropRect = facesRect
    }

    return cropRect
  }

}
