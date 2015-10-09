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

public class GoldenSpiralMetalFilter: NSObject, GoldenSpiralFilter {

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

      let dimension = ceil(min(inputImage.size.width, inputImage.size.height))
      outputImageSize = CGSize(width: dimension * φ, height: dimension)
    }
  }

  private(set) public var colorSpace: CGColorSpaceRef?

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
    guard let inputImage = inputImage else {
      return false
    }

    let maxInputSize = context.inputImageMaximumSize()
    let maxOutputSize = context.outputImageMaximumSize()

    let canProcessInput = min(maxInputSize.width, maxInputSize.height) >= max(inputImage.size.width, inputImage.size.height)
    let canProcessOutput = min(maxOutputSize.width, maxOutputSize.height) >= outputImageSize.width

    return canProcessInput && canProcessOutput
  }

  private(set) public var outputImageSize = CGSizeZero

  public let device: MTLDevice! = MTLCreateSystemDefaultDevice()

  private lazy var commandQueue: MTLCommandQueue = {
    return self.device.newCommandQueueWithMaxCommandBufferCount(5)
  }()

  private(set) public lazy var context: CIContext = {
    return CIContext(MTLDevice: self.device)
  }()

  private func tileImage(image sourceImage: UIImage) -> UIImage? {
    guard let colorSpace = colorSpace else {
      return nil
    }

    guard let (image, portrait) = imagedPreparedForTiling(image: sourceImage) else {
      return nil
    }

    let canvasRect = CGRect(x: 0, y: 0, width: ceil(outputImageSize.width), height: image.extent.height)
    let canvasTexture = createTexture(width: Int(canvasRect.width), height: Int(canvasRect.height))

    let sourceOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    var sourceTexture = createTexture(width: Int(image.extent.width), height: Int(image.extent.height))
    let commandBuffer = commandQueue.commandBuffer()

    context.render(image, toMTLTexture: sourceTexture, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: colorSpace)

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

  private func imagedPreparedForTiling(image sourceImage: UIImage) -> (image: CIImage, portrait: Bool)? {
    let sourceOrientation = sourceImage.EXIFOrientation
    guard let image = CIImage(image: sourceImage)?.imageByApplyingOrientation(sourceOrientation) else {
      return nil
    }

    let portrait = image.extent.height > image.extent.width
    let width = image.extent.width
    let height = image.extent.height
    let dimension = ceil(min(width, height))
    let cropRect = imageCropRect(image: image, toDimension: dimension)

    let preparedImage = image.imageByCroppingToRect(cropRect)

    if portrait {
      return (preparedImage.imageByApplyingOrientation(5), portrait)
    }
    else {
      return (preparedImage.imageByApplyingOrientation(4), portrait)
    }
  }

  // MARK: - Debugging support

  func debugQuickLookObject() -> AnyObject? {
    guard let inputImage = inputImage else {
      return "GoldenSpiralMetalFilter with no images set"
    }

    let spacing: CGFloat = 30
    var inputRect = CGRectZero
    let portrait = inputImage.size.height > inputImage.size.width

    if portrait {
      inputRect.size.height = 400
      inputRect.size.width = inputImage.size.width / inputImage.size.height * inputRect.height
    }
    else {
      inputRect.size.width = 400
      inputRect.size.height = inputImage.size.height / inputImage.size.width * inputRect.width
    }

    var outputRect = CGRectZero
    outputRect.origin.x = inputRect.maxX + spacing
    if portrait {
      outputRect.size.width = inputRect.width
      outputRect.size.height = ceil(inputRect.width * φ)
    }
    else {
      outputRect.size.height = inputRect.height
      outputRect.size.width = ceil(inputRect.height * φ)
    }

    let canvasRect = CGRectUnion(inputRect, outputRect)
    print(canvasRect)
    UIGraphicsBeginImageContextWithOptions(canvasRect.size, false, 0)
    inputImage.drawInRect(inputRect)

    if let _outputImage = _outputImage {
      _outputImage.imageByConvertingFromCIImage(device: device, context: context)?.drawInRect(outputRect)
    }
    else {
      var paths = [UIBezierPath]()
      for rect in tiles() {
        let path = UIBezierPath(rect: rect)
        paths.append(path)
      }

      let bitmapContext = UIGraphicsGetCurrentContext()

      if portrait {
        CGContextSaveGState(bitmapContext)

        let dt = outputRect.width / outputImageSize.width
        var contextTransform = CGAffineTransformIdentity
        contextTransform = CGAffineTransformScale(contextTransform, dt, dt)
        contextTransform = CGAffineTransformRotate(contextTransform, CGFloat(M_PI_2))
        contextTransform = CGAffineTransformTranslate(contextTransform, 0, -5000)
        CGContextConcatCTM(bitmapContext, contextTransform)
      }

      let colorShift = 0.7 / CGFloat(paths.count)
      for (index, path) in paths.enumerate() {
        UIColor(white: 0.2 + colorShift * CGFloat(index), alpha: 1).setFill()
        path.fill()
      }

      if portrait {
        CGContextRestoreGState(bitmapContext)
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

    return UIGraphicsGetImageFromCurrentImageContext()
  }

}
