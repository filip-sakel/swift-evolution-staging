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
internal func race<Value>(
  _ a: Task<Value, Never>,
  _ b: Task<Value, Never>
) async -> (Value, Task<Value, Never>) {
  await withCheckedContinuation { continuation in
    Task {
      await withTaskGroup(
        of: (Value, isFirst: Bool).self
      ) { group in
        group.addTask { (await a.value, isFirst: true ) }
        group.addTask { (await b.value, isFirst: false) }
        
        let (winnerResult, firstWon) = await group.next()!
        continuation.resume(returning: (
          winnerResult,
          firstWon ? b : a
        ))
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
internal func race<Value>(
  _ a: Task<Value, Error>,
  _ b: Task<Value, Error>
) async -> (Result<Value, Error>, Task<Value, Error>) {
  await withCheckedContinuation { continuation in
    Task {
      await withTaskGroup(
        of: (Result<Value, Error>, isFirst: Bool).self
      ) { group in
        group.addTask { (await a.result, isFirst: true ) }
        group.addTask { (await b.result, isFirst: false) }
        
        let (winnerResult, firstWon) = await group.next()!
        continuation.resume(returning: (
          winnerResult,
          firstWon ? b : a
        ))
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
internal func race<A, B>(
  _ a: Task<A, Never>,
  _ b: Task<B, Never>
) async -> Either<A, B> {
  await withCheckedContinuation { continuation in
    Task {
      await withTaskGroup(
        of: Either<A, B>.self
      ) { group in
        group.addTask { await .a(a.value) }
        group.addTask { await .b(b.value) }
        
        let winnerResult = await group.next()!
        
        continuation.resume(returning: winnerResult)
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
internal func race<A, B>(
  _ a: Task<A, Error>,
  _ b: Task<B, Error>
) async throws -> Either<A, B> {
  try await withCheckedThrowingContinuation { continuation in
    Task {
      await withThrowingTaskGroup(
        of: Either<A, B>.self
      ) { group in
        group.addTask { try await .a(a.value) }
        group.addTask { try await .b(b.value) }
        
        let result = await group.nextResult()!
        continuation.resume(with: result)
      }
    }
  }
}
