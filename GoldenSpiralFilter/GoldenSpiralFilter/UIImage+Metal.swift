//
//  UIImage+Metal.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Metal
import UIKit

public extension UIImage {

  public func imageByConvertingFromCIImage(device device: MTLDevice? = nil, context: CIContext? = nil) -> UIImage? {
    if CGImage != nil {
      return self
    }

    guard let image = self.CIImage else {
      return nil
    }

    guard let device = device ?? MTLCreateSystemDefaultDevice() else {
      return nil
    }

    let context = context ?? CIContext(MTLDevice: device)
    return UIImage(CGImage: context.createCGImage(image, fromRect: image.extent))
  }

}
