//
//  GoldenSpiralFilterTests.swift
//  GoldenSpiralFilterTests
//
//  Created by Alexander Kolov on 10/9/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import XCTest
@testable import GoldenSpiralFilter

class GoldenSpiralCoreGraphicsFilterTests: XCTestCase {

  // Tests are not working, unfortunately. See rdar://23053275

  var filter: GoldenSpiralCGFilter!

  let portraitPath: String! = NSBundle.mainBundle().pathForResource("testPortrait", ofType: "jpg")
  let landscapePath: String! = NSBundle.mainBundle().pathForResource("testLandscape", ofType: "jpg")

  lazy var portraitImage: UIImage! = { return UIImage(contentsOfFile: self.portraitPath) }()
  lazy var landscapeImage: UIImage! = { return UIImage(contentsOfFile: self.landscapePath) }()

  override func setUp() {
    super.setUp()
    filter = GoldenSpiralCGFilter()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testThatImageIsProcessableByThisFilter() {
    filter.inputImage = portraitImage
    XCTAssertTrue(filter.canProcessImage, "Test image must be processable by this filter")
  }

  func testThatProducedImageIsCGBacked() {
    filter.inputImage = portraitImage
    XCTAssertNotNil(filter.outputImage?.CGImage)
  }

  func testThatPortraitInputImageProducesPortraitOutput() {
    filter.inputImage = portraitImage
    let outputImage: UIImage! = filter.outputImage

    XCTAssertNotNil(outputImage, "Output image must not be nil")
    XCTAssertTrue(outputImage!.size.height > outputImage!.size.width, "Output image must have same orientation as input")
    XCTAssertEqual(portraitImage.size.width, outputImage.size.width, "Output image must have same width as input")
    XCTAssertEqual(round(portraitImage.size.height * φ), outputImage.size.height, "Output image must have height equal to input multiplied by φ")
  }

  func testThatLandscapeInputImageProducesLandscapeOutput() {
    filter.inputImage = landscapeImage
    let outputImage: UIImage! = filter.outputImage
    XCTAssertTrue(filter.canProcessImage, "Test image must be processable by this filter")
    XCTAssertNotNil(outputImage, "Output image must not be nil")
    XCTAssertTrue(outputImage!.size.width > outputImage!.size.height, "Output image must have same orientation as input")
    XCTAssertEqual(landscapeImage.size.height, outputImage.size.height, "Output image must have same height as input")
    XCTAssertEqual(round(landscapeImage.size.height * φ), outputImage.size.height, "Output image must have width equal to input multiplied by φ")
  }

  func testPerformance() {
    self.measureBlock {
      self.filter.inputImage = self.landscapeImage
      let _ = self.filter.outputImage
    }
  }

}
