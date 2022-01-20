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
public struct AsyncMerge2Sequence<
  Sequence1: AsyncSequence,
  Sequence2: AsyncSequence
>: AsyncSequence where Sequence1.Element == Sequence2.Element {
  public typealias Element = Sequence1.Element
  
  private let sequence1: Sequence1
  private let sequence2: Sequence2
  
  public init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
    self.sequence1 = sequence1
    self.sequence2 = sequence2
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      a: sequence1.makeAsyncIterator(),
      b: sequence2.makeAsyncIterator()
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    fileprivate typealias IteratorA = Sequence1.AsyncIterator
    fileprivate typealias IteratorB = Sequence2.AsyncIterator
    
    private typealias TaskA = Task<
      (Result<Element, Error>?, IteratorA),
      Never
    >
    private typealias TaskB = Task<
      (Result<Element, Error>?, IteratorB),
      Never
    >
    
    private enum TaskState {
      case initial(a: IteratorA, b: IteratorB)
      
      case fetchingA(aRequest: TaskA, b: IteratorB)
      case fetchingB(a: IteratorA, bRequest: TaskB)
        
      case justA(a: IteratorA)
      case justB(b: IteratorB)
    }
    
    private var taskState: TaskState
    
    fileprivate init(a: IteratorA, b: IteratorB) {
      taskState = .initial(a: a, b: b)
    }
    
    public mutating func next() async rethrows -> Element? {
      try await withUncheckedRethrows { try await _next() }
    }
    
    private mutating func _next() async throws -> Element? {
      switch taskState {
      case let .initial(a, b):
        return try await nextWinner(
          fetchA: a.nextTask,
          fetchB: b.nextTask
        )
        
      case let .fetchingA(aRequest, b):
        return try await nextWinner(
          fetchA: aRequest,
          fetchB: b.nextTask
        )
        
      case let .fetchingB(a, bRequest):
        return try await nextWinner(
          fetchA: a.nextTask,
          fetchB: bRequest
        )
        
      case var .justA(a):
        defer { taskState = .justA(a: a) }
        return try await a.next()
        
      case var .justB(b):
        defer { taskState = .justB(b: b) }
        return try await b.next()
      }
    }
    
    private mutating func nextWinner(
      fetchA: TaskA,
      fetchB: TaskB
    ) async throws -> Element? {
      switch await race(fetchA, fetchB) {
      case let .a((aResult?, aIterator)):
        taskState = .fetchingB(a: aIterator, bRequest: fetchB)
        return try aResult.value
        
      case let .b((bResult?, bIterator)):
        taskState = .fetchingA(aRequest: fetchA, b: bIterator)
        return try bResult.value
        
      case .a((nil, _)):
        let (bResult, bIterator) = await fetchB.value
        
        taskState = .justB(b: bIterator)
        
        return try bResult?.value
        
      case .b((nil, _)):
        let (aResult, aIterator) = await fetchA.value
        
        taskState = .justA(a: aIterator)
        
        return try aResult?.value
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func merge<Sequence1, Sequence2>(
  _ sequence1: Sequence1,
  _ sequence2: Sequence2
) -> AsyncMerge2Sequence<Sequence1, Sequence2> {
    AsyncMerge2Sequence(sequence1, sequence2)
}
