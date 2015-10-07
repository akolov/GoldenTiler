//
//  Rdar23011575Checker.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/7/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

protocol Rdar23011575CheckerProtocol: class {
  func rdar23011575Checker(checker: Rdar23011575Checker, didHitThresholdValue threshold: NSTimeInterval)
}

class Rdar23011575Checker: NSObject {

  /// Threshold after which `encodeToCommandBuffer:sourceTexture:destinationTexture` is considered to be hanging indefinitely
  static let threshold: NSTimeInterval = 10

  weak var delegate: Rdar23011575CheckerProtocol?

  private var timer: NSTimer?
  private var elapsed: NSTimeInterval = 0

  func start() {
    guard timer == nil else {
      return
    }

    timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("onTimer:"), userInfo: nil, repeats: true)
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    elapsed = 0
  }

  func onTimer(timer: NSTimer) {
    elapsed += timer.timeInterval
    if elapsed > self.dynamicType.threshold {
      timer.invalidate()
      delegate?.rdar23011575Checker(self, didHitThresholdValue: elapsed)
    }
  }

}
