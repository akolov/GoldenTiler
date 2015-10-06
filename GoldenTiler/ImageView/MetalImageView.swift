//
//  MetalImageView.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Metal
import MetalKit
import UIKit

class MetalImageView: MTKView, ImageView {

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    device = MTLCreateSystemDefaultDevice()
    commonInit()
  }

  required init() {
    let device = MTLCreateSystemDefaultDevice()
    super.init(frame: CGRectZero, device: device)
    commonInit()
  }

  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    commonInit()
  }

  override func drawRect(rect: CGRect) {
    // Metal context origin is bottom left, so let's flip image to display it correctly
    guard let ciImage = image?.CIImage?.imageByApplyingOrientation(4) else {
      return
    }

    let commandBuffer = commandQueue.commandBufferWithUnretainedReferences()

    guard let currentDrawable = currentDrawable, colorSpace = colorSpace else {
      return
    }

    context.render(ciImage, toMTLTexture: currentDrawable.texture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: colorSpace)

    commandBuffer.presentDrawable(currentDrawable)
    commandBuffer.commit()
  }

  // MARK: -

  var image: UIImage? {
    didSet {
      guard let ciImage = image?.CIImage else {
        return
      }

      frame = ciImage.extent
      drawableSize = ciImage.extent.size

      colorSpace = ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
      draw()
    }
  }

  private var colorSpace: CGColorSpaceRef?

  private lazy var commandQueue: MTLCommandQueue = {
    return self.device!.newCommandQueueWithMaxCommandBufferCount(5)
  }()

  private lazy var context: CIContext = {
    return CIContext(MTLDevice: self.device!, options: [kCIContextUseSoftwareRenderer: false])
  }()

  private func commonInit() {
    framebufferOnly = false
    enableSetNeedsDisplay = false
    paused = true
    clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
  }

}
