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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncIteratorProtocol {
  internal var nextTask: Task<
    (Result<Element, Error>?, Self),
    Never
  > {
      Task {
        var iteratorCopy = self
        
        do {
          let element = try await iteratorCopy.next()
          return (element.map(Result.success), iteratorCopy)
        } catch {
          return (.failure(error), iteratorCopy)
        }
      }
  }
}
