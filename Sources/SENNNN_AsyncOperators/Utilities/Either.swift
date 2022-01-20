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

internal enum Either<A, B> {
  case a(A), b(B)
  
  internal var isA: Bool {
    switch self {
    case .a: return true
    case .b: return false
    }
  }
  
  internal var isB: Bool {
    !isA
  }
}
