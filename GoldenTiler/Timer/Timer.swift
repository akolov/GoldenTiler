//
//  Timer.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/5/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

struct Timer {

  static func run(@noescape closure: () -> Void) -> Timer? {
    let start = mach_absolute_time()

    closure()

    let end = mach_absolute_time()

    var timebaseInfo = mach_timebase_info()
    guard mach_timebase_info(&timebaseInfo) == KERN_SUCCESS else {
      return nil
    }

    // http://stackoverflow.com/questions/23378063/how-can-i-use-mach-absolute-time-without-overflowing
    if timebaseInfo.denom > 1024 {
      let frac = Double(timebaseInfo.numer) / Double(timebaseInfo.denom)
      timebaseInfo.denom = 1024
      timebaseInfo.numer = UInt32(Double(timebaseInfo.denom) * frac + 0.5)
    }

    return Timer(nanoseconds: (end - start) * UInt64(timebaseInfo.numer / timebaseInfo.denom))
  }

  private(set) var nanoseconds: UInt64 = 0

  var microseconds: Double {
    return Double(nanoseconds) / Double(NSEC_PER_USEC)
  }

  var milliseconds: Double {
    return Double(nanoseconds) / Double(NSEC_PER_MSEC)
  }

  var seconds: Double {
    return Double(nanoseconds) / Double(NSEC_PER_SEC)
  }

  private init(nanoseconds: UInt64) {
    self.nanoseconds = nanoseconds
  }

}


