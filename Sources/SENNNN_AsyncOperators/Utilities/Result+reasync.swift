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
  public init(
    catching body: () async throws -> Success
  ) async {
    do {
      self = try await .success(body())
    } catch {
      self = .failure(error)
    }
  }
}
