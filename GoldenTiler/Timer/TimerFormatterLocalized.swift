//
//  TimerFormatterLocalized.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

final class TimerLocalized {

  private static var TableName = "TimerFormatter"

  static var UnitNanosecond: String { return NSLocalizedString("unit.nanosecond", tableName: TableName, comment: "Nanoseconds format") }
  static var UnitMicrosecond: String { return NSLocalizedString("unit.microsecond", tableName: TableName, comment: "Microseconds format") }
  static var UnitMillisecond: String { return NSLocalizedString("unit.millisecond", tableName: TableName, comment: "Milliseconds format") }
  static var UnitSecond: String { return NSLocalizedString("unit.second", tableName: TableName, comment: "Seconds format") }

}
