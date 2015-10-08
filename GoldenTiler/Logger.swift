//
//  Logger.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/8/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

final class Logger {

  static func log(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    #if DEBUG
      print("\(file) \(function):\(line) \(message)")
    #endif
  }

}
