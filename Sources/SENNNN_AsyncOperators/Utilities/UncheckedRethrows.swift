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

internal func withUncheckedRethrows<Value>(
  _ body: () throws -> Value
) rethrows -> Value {
  try body()
}

internal func withUncheckedRethrows<Value>(
  _ body: () async throws -> Value
) async rethrows -> Value {
  try await body()
}
