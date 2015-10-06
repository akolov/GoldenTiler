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
      return String.localizedStringWithFormat(TimerLocalized.UnitNanosecond, timer.nanoseconds)
    case .Microsecond:
      return String.localizedStringWithFormat(TimerLocalized.UnitMicrosecond, timer.microseconds)
    case .Millisecond:
      return String.localizedStringWithFormat(TimerLocalized.UnitMillisecond, timer.milliseconds)
    case .Second:
      return String.localizedStringWithFormat(TimerLocalized.UnitSecond, timer.seconds)
    }
  }

  /// This method is not supported for TimerFormatter class
  override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
    return false
  }

}
