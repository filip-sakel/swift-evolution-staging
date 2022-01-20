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
public struct AsyncCombineLatest2Sequence<
  Sequence1: AsyncSequence,
  Sequence2: AsyncSequence
>: AsyncSequence {
  public typealias Element = (Sequence1.Element, Sequence2.Element)
  
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
      (Result<IteratorA.Element, Error>?, IteratorA),
      Never
    >
    
    private typealias TaskB = Task<
      (Result<IteratorB.Element, Error>?, IteratorB),
      Never
    >
    
    private enum TaskState {
      case initial(
        a: IteratorA,
        b: IteratorB
      )
      
      case fetchingA(
        aRequest: TaskA,
        b: IteratorB
      )
      case fetchingB(
        a: IteratorA,
        bRequest: TaskB
      )
      
      case finished
    }
    
    private var lastA: IteratorA.Element?
    private var lastB: IteratorB.Element? = nil
    private var taskState: TaskState
    
    fileprivate init(a: IteratorA, b: IteratorB) {
      taskState = .initial(a: a, b: b)
    }
    
    public mutating func next() async rethrows -> Element? {
      try await withUncheckedRethrows { try await _next() }
    }
    
    private mutating func _next() async throws -> Element? {
      guard let fetchRequests = fetchRequests else { return nil }
      
      try await updateState(
        fetchA: fetchRequests.0,
        fetchB: fetchRequests.1
      )
      
      guard let lastA = lastA, let lastB = lastB else {
        return try await _next()
      }
      
      return (lastA, lastB)
    }
    
    private var fetchRequests: (TaskA, TaskB)? {
      switch taskState {
      case let .initial(a, b):
        return (a.nextTask, b.nextTask)
        
      case let .fetchingB(a, bRequest):
        return (a.nextTask, bRequest)
        
      case let .fetchingA(aRequest, b):
        return (aRequest, b.nextTask)
        
      case .finished:
        return nil
      }
    }
    
    private mutating func updateState(
      fetchA: TaskA,
      fetchB: TaskB
    ) async throws {
      switch await race(fetchA, fetchB) {
      case let .a((aResult?, aIterator)):
        taskState = .fetchingB(a: aIterator, bRequest: fetchB)
        lastA = try aResult.value
        
      case let .b((bResult?, bIterator)):
        taskState = .fetchingA(aRequest: fetchA, b: bIterator)
        lastB = try bResult.value
        
      case .a((nil, _)), .b((nil, _)):
        taskState = .finished
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func combineLatest<Sequence1, Sequence2>(
  _ sequence1: Sequence1,
  _ sequence2: Sequence2
) -> AsyncCombineLatest2Sequence<Sequence1, Sequence2> {
    AsyncCombineLatest2Sequence(sequence1, sequence2)
}
