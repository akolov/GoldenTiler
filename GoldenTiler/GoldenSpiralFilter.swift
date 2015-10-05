//
//  GoldenSpiralFilter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/4/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation
import CoreImage
import ImageIO
import Metal
import MetalPerformanceShaders

class GoldenSpiralFilter: CIFilter {

  override var outputImage: CIImage? {
    guard let inputImage = inputImage else {
      return nil
    }

    return tileImage(inputImage)
  }

  // MARK: -

  var steps = 16

  var inputImage: CIImage? {
    didSet {
      colorSpace = inputImage?.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    }
  }

  private var colorSpace: CGColorSpaceRef?

  private let device: MTLDevice! = MTLCreateSystemDefaultDevice()

  lazy var commandQueue: MTLCommandQueue = {
    return self.device.newCommandQueue()
  }()

  lazy var commandBuffer: MTLCommandBuffer = {
    return self.commandQueue.commandBuffer()
  }()

  private func tileImage(image: CIImage) -> CIImage? {
    guard let colorSpace = colorSpace else {
      return nil
    }

    let context = CIContext(MTLDevice: device)
    let dimension = min(image.extent.width, image.extent.height)

    guard let cropped = squareCropImage(image, toDimension: dimension) else {
      return nil
    }

    let φ: CGFloat = (1 + sqrt(5.0)) / 2.0

    let canvasRect = CGRect(x: 0, y: 0, width: ceil(dimension * φ), height: dimension)
    let canvasTexture = createTexture(width: Int(canvasRect.width), height: Int(canvasRect.height))

    let sourceOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    let sourceRect = CGRect(x: 0, y: 0, width: dimension, height: dimension)
    var sourceTexture = createTexture(width: Int(dimension), height: Int(dimension))

    context.render(cropped, toMTLTexture: sourceTexture, commandBuffer: commandBuffer, bounds: sourceRect, colorSpace: colorSpace)

    var x = 0, y = 0, counter = 0

    while true {
      let a = ceil(CGFloat(sourceRect.width) / pow(φ, CGFloat(counter)))
      let b = ceil(CGFloat(sourceRect.width) / pow(φ, CGFloat(counter) + 1))

      // Bail out when significant part is less than 2 pixels
      if a < 2 {
        break
      }

      let texture = createScaledTexture(sourceTexture, dimension: Int(a))

      var origin: MTLOrigin!

      switch counter % 4 {
      case 0:
        origin = MTLOrigin(x: x, y: y, z: 0)
        x += Int(ceil(a + b))

      case 1:
        origin = MTLOrigin(x: x - Int(a), y: y, z: 0)
        y += Int(ceil(a + b))

      case 2:
        origin = MTLOrigin(x: x - Int(a), y: y - Int(a), z: 0)
        x -= Int(ceil(a + b))

      case 3:
        origin = MTLOrigin(x: x, y: y - Int(a), z: 0)
        y -= Int(ceil(a + b))

      default:
        break
      }

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
      counter++
    }

    commandBuffer.commit()

    return CIImage(MTLTexture: canvasTexture, options: [kCIImageColorSpace: colorSpace])
  }

  private func squareCropImage(image: CIImage, toDimension dimension: CGFloat) -> CIImage? {
    let context = CIContext()
    let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    let orientation: AnyObject = image.properties[kCGImagePropertyOrientation as String] ?? 1
    let features = detector.featuresInImage(image, options: [CIDetectorImageOrientation: orientation])

    let cropRect: CGRect
    if features.count == 0 {
      cropRect = CGRect(x: (image.extent.width - dimension) / 2.0, y: (image.extent.height - dimension) / 2.0, width: dimension, height: dimension)
    }
    else {
      // We've detected some faces, set crop rect to center around faces
      var facesRect = features.map { $0.bounds }.reduce(CGRectZero, combine: CGRectUnion)
      facesRect.insetInPlace(dx: (dimension - facesRect.width) / -2.0, dy: (dimension - facesRect.height) / -2.0)
      facesRect.offsetInPlace(dx: facesRect.minX < 0 ? -facesRect.minX : 0, dy: facesRect.minY < 0 ? -facesRect.minY : 0)
      cropRect = facesRect
    }
    
    let cropped = image.imageByCroppingToRect(cropRect)
    let transform = CGAffineTransformMakeTranslation(-cropped.extent.minX, -cropped.extent.minY)
    return cropped.imageByApplyingTransform(transform)
  }

  private func createTexture(width width: Int, height: Int) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.ShaderRead, .ShaderWrite]
    return device.newTextureWithDescriptor(descriptor)
  }

  private func createScaledTexture(sourceTexture: MTLTexture, dimension: Int) -> MTLTexture {
    let scale = MPSImageLanczosScale(device: device)
    let factor = Double(dimension) / Double(sourceTexture.width)
    var scaleTransform = MPSScaleTransform(scaleX: factor, scaleY: factor, translateX: 0, translateY: 0)

    withUnsafePointer(&scaleTransform) { ptr in
      scale.scaleTransform = ptr
    }

    let texture = createTexture(width: dimension, height: dimension)
    scale.encodeToCommandBuffer(commandBuffer, sourceTexture: sourceTexture, destinationTexture: texture)
    return texture
  }

  private func transposeTexture(sourceTexture: MTLTexture) -> MTLTexture {
    let texture = createTexture(width: sourceTexture.height, height: sourceTexture.width)

    let transpose = MPSImageTranspose(device: device)
    transpose.encodeToCommandBuffer(commandBuffer, sourceTexture: sourceTexture, destinationTexture: texture)

    return texture
  }

}
