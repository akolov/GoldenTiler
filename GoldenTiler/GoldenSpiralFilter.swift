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

class GoldenSpiralFilter: CIFilter {

  override var outputImage: CIImage? {
    guard let inputImage = inputImage else {
      return nil
    }

    return tileImage(inputImage)
  }

  // MARK: -

  var inputImage: CIImage? {
    didSet {
      colorSpace = inputImage?.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    }
  }

  private var colorSpace: CGColorSpaceRef?

  private static let φ: CGFloat = (1 + sqrt(5.0)) / 2.0

  private func tileImage(image: CIImage) -> CIImage? {
    guard let device = MTLCreateSystemDefaultDevice() else {
      return nil
    }

    let context = CIContext(MTLDevice: device)
    let dimension = min(image.extent.width, image.extent.height)

    guard let cropped = squareCropImage(image, toDimension: dimension) else {
      return nil
    }

    let canvas = CGRect(x: 0, y: 0, width: floor(dimension * self.dynamicType.φ), height: dimension)
    let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: Int(canvas.width), height: Int(canvas.height), mipmapped: false)
    descriptor.usage = [.RenderTarget, .ShaderRead, .ShaderWrite]

    let texture = device.newTextureWithDescriptor(descriptor)
    let commandQueue = device.newCommandQueue()
    let commandBuffer = commandQueue.commandBufferWithUnretainedReferences()

    guard let colorSpace = colorSpace else {
      return nil
    }

    context.render(cropped, toMTLTexture: texture, commandBuffer: commandBuffer, bounds: canvas, colorSpace: colorSpace)

    commandBuffer.commit()

    return CIImage(MTLTexture: texture, options: [kCIImageColorSpace: colorSpace])
  }

  private func squareCropImage(image: CIImage, toDimension dimension: CGFloat) -> CIImage? {
    let scale = dimension / min(image.extent.width, image.extent.height)
    let filter = CIFilter(name: "CILanczosScaleTransform", withInputParameters: [
      kCIInputImageKey: image,
      kCIInputScaleKey: scale
      ])

    guard let rescaled = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
      return nil
    }

    let context = CIContext()
    let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    let orientation: AnyObject = image.properties[kCGImagePropertyOrientation as String] ?? 1
    let features = detector.featuresInImage(rescaled, options: [CIDetectorImageOrientation: orientation])

    let cropRect: CGRect
    if features.count == 0 {
      cropRect = CGRect(x: (rescaled.extent.width - dimension) / 2.0, y: (rescaled.extent.height - dimension) / 2.0, width: dimension, height: dimension)
    }
    else {
      // We've detected some faces, set crop rect to center around faces
      var facesRect = features.map { $0.bounds }.reduce(CGRectZero, combine: CGRectUnion)
      facesRect.insetInPlace(dx: (dimension - facesRect.width) / -2.0, dy: (dimension - facesRect.height) / -2.0)
      facesRect.offsetInPlace(dx: facesRect.minX < 0 ? -facesRect.minX : 0, dy: facesRect.minY < 0 ? -facesRect.minY : 0)
      cropRect = facesRect
    }
    
    return rescaled.imageByCroppingToRect(cropRect)
  }
  
}
