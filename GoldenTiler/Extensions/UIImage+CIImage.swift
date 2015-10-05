//
//  UIImage+CIImage.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import UIKit

extension UIImage {

  func CIImageWithAppliedOrientation() -> CoreImage.CIImage? {
    var image = CoreImage.CIImage(image: self)

    switch imageOrientation {
    case .Up:
      image = image?.imageByApplyingOrientation(1)
    case .Down:
      image = image?.imageByApplyingOrientation(3)
    case .Left:
      image = image?.imageByApplyingOrientation(8)
    case .Right:
      image = image?.imageByApplyingOrientation(6)
    case .UpMirrored:
      image = image?.imageByApplyingOrientation(2)
    case .DownMirrored:
      image = image?.imageByApplyingOrientation(4)
    case .LeftMirrored:
      image = image?.imageByApplyingOrientation(5)
    case .RightMirrored:
      image = image?.imageByApplyingOrientation(7)
    }

    return image
  }

}
