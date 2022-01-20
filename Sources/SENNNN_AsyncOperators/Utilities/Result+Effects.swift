//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
extension Result {
  internal var value: Success {
    get throws {
      try get()
    }
  }
}

extension Result where Failure == Never {
  internal var value: Success {
    get {
      switch self {
      case let .success(value):
        return value
      case let .failure(error):
        switch error {}
      }
    }
  }
}
