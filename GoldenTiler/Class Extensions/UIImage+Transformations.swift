//
//  UIImage+Transformations.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import UIKit

extension UIImage {

  func imageByFixingOrientation() -> UIImage? {
    if imageOrientation == .Up {
      return self
    }

    var transform = CGAffineTransformIdentity

    switch imageOrientation {
    case .Down, .DownMirrored:
      transform = CGAffineTransformTranslate(transform, size.width, size.height)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI))

    case .Left, .LeftMirrored:
      transform = CGAffineTransformTranslate(transform, size.width, 0)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))

    case .Right, .RightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, size.height)
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))

    default:
      break
    }

    switch imageOrientation {
    case .UpMirrored, .DownMirrored:
      transform = CGAffineTransformTranslate(transform, size.width, 0)
      transform = CGAffineTransformScale(transform, -1, 1)

    case .LeftMirrored,.RightMirrored:
      transform = CGAffineTransformTranslate(transform, size.height, 0)
      transform = CGAffineTransformScale(transform, -1, 1)

    default:
      break
    }

    let bitsPerComponent = CGImageGetBitsPerComponent(CGImage)
    let bitmapInfo = CGImageGetBitmapInfo(CGImage)
    let colorSpace = CGImageGetColorSpace(CGImage)
    let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), bitsPerComponent, 0, colorSpace, bitmapInfo.rawValue)

    CGContextConcatCTM(context, transform)
    switch (imageOrientation) {
    case .Left, .LeftMirrored, .Right, .RightMirrored:
      CGContextDrawImage(context, CGRectMake(0, 0, size.height, size.width), CGImage)

    default:
      CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), CGImage)
    }

    guard let image = CGBitmapContextCreateImage(context) else {
      return nil
    }

    return UIImage(CGImage: image)
  }

  var EXIFOrientation: Int32 {
    switch imageOrientation {
    case .Up:
      return 1
    case .Down:
      return 3
    case .Left:
      return 8
    case .Right:
      return 6
    case .UpMirrored:
      return 2
    case .DownMirrored:
      return 4
    case .LeftMirrored:
      return 5
    case .RightMirrored:
      return 7
    }
  }

}
