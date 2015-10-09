//
//  GoldenSpiralFilterTests.swift
//  GoldenSpiralFilterTests
//
//  Created by Alexander Kolov on 10/9/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import XCTest
@testable import GoldenSpiralFilter

class GoldenSpiralMetalFilterTests: XCTestCase {

  let filter = GoldenSpiralMetalFilter()

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testThatPortraitInputImageProducesPortraitOutput() {
    let portraitPath: NSString! = NSBundle.mainBundle().pathForResource("testPortrait", ofType: "jpg")
    let inputImage: UIImage! = UIImage(contentsOfFile: portraitPath)
    filter.inputImage = inputImage
    let outputImage: UIImage! = filter.outputImage
    XCTAssertTrue(filter.canProcessImage, "Test image must be processable by this filter")
    XCTAssertNotNil(outputImage, "Output image must not be nil")
    XCTAssertTrue(outputImage!.size.height > outputImage!.size.width, "Output image must have same orientation as input")
    XCTAssertEqual(inputImage.size.width == outputImage.size.width, "Output image must have same width as input")
    XCTAssertEqual(round(inputImage.size.height * φ) == outputImage.size.height, "Output image must have height equal to input multiplied by φ")
  }

  func testThatLandscapeInputImageProducesLandscapeOutput() {
    let portraitPath: NSString! = NSBundle.mainBundle().pathForResource("testLandscape", ofType: "jpg")
    let inputImage: UIImage! = UIImage(contentsOfFile: portraitPath)
    filter.inputImage = inputImage
    let outputImage: UIImage! = filter.outputImage
    XCTAssertTrue(filter.canProcessImage, "Test image must be processable by this filter")
    XCTAssertNotNil(outputImage, "Output image must not be nil")
    XCTAssertTrue(outputImage!.size.width > outputImage!.size.height, "Output image must have same orientation as input")
    XCTAssertEqual(inputImage.size.height == outputImage.size.height, "Output image must have same height as input")
    XCTAssertEqual(round(inputImage.size.height * φ) == outputImage.size.height, "Output image must have width equal to input multiplied by φ")
  }

  func testPerformance() {
    let portraitPath: NSString! = NSBundle.mainBundle().pathForResource("testPortrait", ofType: "jpg")
    let inputImage: UIImage! = UIImage(contentsOfFile: portraitPath)

    self.measureBlock {
      filter.inputImage = inputImage
      let outputImage = filter.outputImage
    }
  }

}
