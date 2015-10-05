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

class MetalImageView: MTKView {

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    device = MTLCreateSystemDefaultDevice()
    commonInit()
  }

  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    commonInit()
  }

  override func drawRect(rect: CGRect) {
    guard let image = image else {
      return
    }

    let commandBuffer = commandQueue.commandBufferWithUnretainedReferences()

    guard let currentDrawable = currentDrawable, colorSpace = colorSpace else {
      return
    }

    context.render(image, toMTLTexture: currentDrawable.texture, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: colorSpace)

    commandBuffer.presentDrawable(currentDrawable)
    commandBuffer.commit()
  }

  // MARK: -

  var image: CIImage? {
    didSet {
      guard let image = image else {
        return
      }

      frame = image.extent
      drawableSize = image.extent.size

      colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
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
