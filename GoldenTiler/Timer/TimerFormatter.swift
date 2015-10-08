//
//  TimerFormatter.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

class TimerFormatter: NSFormatter {

  enum Unit {
    case Nanosecond, Microsecond, Millisecond, Second
  }

  /// Returns timer string for the provided value in nanoseconds
  override func stringForObjectValue(obj: AnyObject) -> String? {
    guard let obj = obj as? Timer else {
      return nil
    }

    return stringFromTimer(obj, unit: .Nanosecond)
  }

  /// Returns timer string for the provided value and unit
  func stringFromTimer(timer: Timer, unit: Unit) -> String? {
    switch unit {
    case .Nanosecond:
      return String.localizedStringWithFormat(TimerLocalizable.UnitNanosecond, timer.nanoseconds)
    case .Microsecond:
      return String.localizedStringWithFormat(TimerLocalizable.UnitMicrosecond, timer.microseconds)
    case .Millisecond:
      return String.localizedStringWithFormat(TimerLocalizable.UnitMillisecond, timer.milliseconds)
    case .Second:
      return String.localizedStringWithFormat(TimerLocalizable.UnitSecond, timer.seconds)
    }
  }

  /// Returns timer string with the best human readable unit
  func stringFromTimer(timer: Timer) -> String? {
    if timer.seconds >= 1.0 {
      return stringFromTimer(timer, unit: .Second)
    }
    else if timer.milliseconds >= 1.0 {
      return stringFromTimer(timer, unit: .Millisecond)
    }
    else if timer.microseconds >= 1.0 {
      return stringFromTimer(timer, unit: .Microsecond)
    }

    return stringFromTimer(timer, unit: .Nanosecond)
  }

  /// This method is not supported for TimerFormatter class
  override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
    return false
  }

}
