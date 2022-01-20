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
public struct AsyncTimeoutSequence<
  Base: AsyncSequence,
  ClockType: Clock
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let duration: Duration
  private let clock: ClockType
  
  fileprivate init(
    base: Base,
    duration: Duration,
    clock: ClockType
  ) {
    self.base = base
    self.duration = duration
    self.clock = clock
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: base.makeAsyncIterator(),
      duration: duration,
      clock: clock
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private let duration: Duration
    private let clock: ClockType
    
    private enum State {
      case requesting(base: Base.AsyncIterator)
      case timedOut
    }
    
    private var state: State
    
    fileprivate init(
      base: Base.AsyncIterator,
      duration: Duration,
      clock: ClockType
    ) {
      self.duration = duration
      self.clock = clock
      
      state = .requesting(base: base)
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await withUncheckedRethrows { try await _next() }
    }
    
    private mutating func _next() async throws -> Base.Element? {
      guard case let .requesting(baseCopy) = state else {
        return nil
      }
      
      let nextTask = baseCopy.nextTask, sleepTask = self.sleepTask
      
      switch await race(nextTask, sleepTask) {
      case let .a((result, newBase)):
        state = .requesting(base: newBase)
        
        sleepTask.cancel()
        
        return try result?.value
        
      case .b:
        state = .timedOut
        
        nextTask.cancel()
        
        return nil
      }
    }
    
    private var sleepTask: Task<Void, Never> {
      let duration = duration, clock = clock
      
      let task = Task<Void, Never> {
        try? await Task.sleep(duration, clock: clock)
      }
      
      return task
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func timeout<ClockType>(
    _ duration: Duration,
    clock: ClockType
  ) -> AsyncTimeoutSequence<Self, ClockType> {
    AsyncTimeoutSequence(
      base: self,
      duration: duration,
      clock: clock
    )
  }
  
  public func timeout(
    _ duration: Duration
  ) -> AsyncTimeoutSequence<Self, ContinuousClock> {
    AsyncTimeoutSequence(
      base: self,
      duration: duration,
      clock: .continuous
    )
  }
}
