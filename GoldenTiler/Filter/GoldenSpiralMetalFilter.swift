//
//  GoldenSpiralMetalFilter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation
import CoreImage
import ImageIO
import Metal
import MetalKit
import MetalPerformanceShaders
import UIKit

class GoldenSpiralMetalFilter: GoldenSpiralFilter {

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

      portrait = inputImage.size.height > inputImage.size.width
    }
  }

  private(set) var portrait: Bool = false
  var colorSpace: CGColorSpaceRef?

  var outputImage: UIImage? {
    guard let inputImage = inputImage else {
      return nil
    }

    return tileImage(image: inputImage)
  }

  var canProcessImage: Bool {
    guard let inputImage = inputImage else {
      return false
    }

    let maxInputSize = context.inputImageMaximumSize()
    let maxOutputSize = context.outputImageMaximumSize()

    let canProcessInput = min(maxInputSize.width, maxInputSize.height) >= max(inputImage.size.width, inputImage.size.height)
    let canProcessOutput = min(maxOutputSize.width, maxOutputSize.height) >= outputImageSize.width

    return canProcessInput && canProcessOutput
  }

  private(set) var outputImageSize = CGSizeZero

  private let device: MTLDevice! = MTLCreateSystemDefaultDevice()

  private lazy var commandQueue: MTLCommandQueue = {
    return self.device.newCommandQueue()
  }()

  private(set) lazy var context: CIContext = {
    return CIContext(MTLDevice: self.device)
  }()

  private func tileImage(image sourceImage: UIImage) -> UIImage? {
    guard let colorSpace = colorSpace else {
      return nil
    }

    guard let image = sourceImage.CGImage else {
      return nil
    }

    let width = CGFloat(CGImageGetWidth(image))
    let height = CGFloat(CGImageGetHeight(image))
    let dimension = ceil(min(width, height))
    let cropRect = imageCropRect(image: image, toDimension: dimension)

    guard let cropped = CGImageCreateWithImageInRect(image, cropRect) else {
      return nil
    }

    guard let flipped = imageByFixingOrientation(image: cropped) else {
      return nil
    }

    let canvasRect = CGRect(x: 0, y: 0, width: outputImageSize.width, height: dimension)
    let canvasTexture = createTexture(width: Int(canvasRect.width), height: Int(canvasRect.height))

    let sourceOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    let textureLoader = MTKTextureLoader(device: device)
    var sourceTexture: MTLTexture!

    do {
      sourceTexture = try textureLoader.newTextureWithCGImage(flipped, options: [MTKTextureLoaderOptionTextureUsage: MTLTextureUsage.ShaderRead.rawValue])
    }
    catch let error as NSError {
      print("\(error.localizedDescription): \(error.localizedFailureReason)")
      return nil
    }

    guard sourceTexture != nil else {
      return nil
    }

    let commandBuffer = commandQueue.commandBuffer()

    for tile in tiles() {
      let origin = MTLOrigin(x: Int(tile.origin.x), y: Int(tile.origin.y), z: 0)

      let texture = createScaledTexture(sourceTexture, dimension: Int(tile.width), commandBuffer: commandBuffer)
      var sourceSize = MTLSize(width: texture.width, height: texture.height, depth: 1)

      if sourceSize.width + origin.x > Int(canvasRect.width) {
        sourceSize.width = Int(canvasRect.width) - origin.x
      }

      if sourceSize.height + origin.y > Int(canvasRect.height) {
        sourceSize.height = Int(canvasRect.height) - origin.y
      }

      let encoder = commandBuffer.blitCommandEncoder()
      encoder.copyFromTexture(texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceOrigin, sourceSize: sourceSize, toTexture: canvasTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: origin)
      encoder.endEncoding()

      sourceTexture = texture
    }

    commandBuffer.commit()

    var tiledImage = CIImage(MTLTexture: canvasTexture, options: [kCIImageColorSpace: colorSpace])
    if portrait {
      tiledImage = tiledImage.imageByApplyingOrientation(5)
    }
    else {
      tiledImage = tiledImage.imageByApplyingOrientation(4)
    }

    return UIImage(CIImage: tiledImage)
  }

  private func createTexture(width width: Int, height: Int) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.ShaderRead, .ShaderWrite]
    return device.newTextureWithDescriptor(descriptor)
  }

  private func createScaledTexture(sourceTexture: MTLTexture, dimension: Int, commandBuffer: MTLCommandBuffer) -> MTLTexture {
    let scale = MPSImageLanczosScale(device: device)
    let factor = Double(dimension) / Double(sourceTexture.width)

    if factor == 1 {
      return sourceTexture
    }

    var scaleTransform = MPSScaleTransform(scaleX: factor, scaleY: factor, translateX: 0, translateY: 0)

    withUnsafePointer(&scaleTransform) { ptr in
      scale.scaleTransform = ptr
    }

    let texture = createTexture(width: dimension, height: dimension)
    scale.encodeToCommandBuffer(commandBuffer, sourceTexture: sourceTexture, destinationTexture: texture)
    return texture
  }

}
