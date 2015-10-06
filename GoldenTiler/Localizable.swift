//
//  Localizable.swift
//  GoldenTiler
//
//  Created by Alexander Kolov on 10/6/15.
//  Copyright © 2015 Alexander Kolov. All rights reserved.
//

import Foundation

final class Localizable {

  final class Save {

    final class Success {

      static var Title: String { return NSLocalizedString("saved.success.title", comment: "Title of the save success message") }
      static var Message: String { return NSLocalizedString("saved.success.message", comment: "Text of the save success message") }

    }

    final class Error {

      static var Title: String { return NSLocalizedString("saved.error.title", comment: "Title of the save error message") }
      static var Message: String { return NSLocalizedString("saved.error.message", comment: "Text of the save error message, when localized description is not available") }
      
    }

  }

  final class MetalError {
    static var Title: String { return NSLocalizedString("metal.error.title", comment: "Title of the metal error message") }
    static var Message: String { return NSLocalizedString("metal.error.message", comment: "Text of the metal error message") }
  }

  final class Button {

    static var OK: String { return NSLocalizedString("button.OK", comment: "OK button title") }

  }

}
