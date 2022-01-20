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

extension Result where Failure == Error {
  internal static func unwrap(
    catching body: () throws -> Success?
  ) -> Result? {
    do {
      guard let value = try body() else { return nil }
      return .success(value)
    } catch {
      return .failure(error)
    }
  }
  
  internal static func unwrap(
    catching body: () async throws -> Success?
  ) async -> Result? {
    do {
      guard let value = try await body() else { return nil }
      return .success(value)
    } catch {
      return .failure(error)
    }
  }
}
