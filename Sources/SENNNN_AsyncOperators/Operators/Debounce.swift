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
public struct AsyncDebounceSequence<
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
    private typealias NextTask = Task<
      (Result<Base.Element, Error>?, Base.AsyncIterator),
      Never
    >
    
    private enum State {
      case idle(base: Base.AsyncIterator)
      
      // Fetching occurs when the cooldown period finishes before
      // the next element (after the candidate) is emitted. Thus,
      // the candidate is returned, but the next task needs to be
      // saved.
      case fetching(NextTask)
    }
    
    private let duration: Duration
    private let clock: ClockType
    
    private var state: State
    
    fileprivate init(
      base: Base.AsyncIterator,
      duration: Duration,
      clock: ClockType
    ) {
      self.duration = duration
      self.clock = clock
      
      state = .idle(base: base)
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await withUncheckedRethrows {
        let (result, newBase) = await findCandidate()
        state = .idle(base: newBase)
        
        guard let element = try result?.value else {
          return nil
        }
        
        return try await nextAndSave(
          candidate: element,
          nextTask: newBase.nextTask
        )
      }
    }
    
    private mutating func findCandidate() async -> (
      Result<Base.Element, Error>?,
      Base.AsyncIterator
    ) {
      switch state {
      case let .idle(base):
        return await base.nextTask.value
        
      case let .fetching(nextTask):
        return await nextTask.value
      }
    }
    
    private mutating func nextAndSave(
      candidate: Base.Element,
      nextTask: Task<
        (Result<Base.Element, Error>?, Base.AsyncIterator),
        Never
      >
    ) async throws -> Base.Element? {
      switch await race(nextTask, sleepTask) {
      case let .a((result?, newBase)):
        // Received new element within cooldown period; restart
        // race.
        
        // Save state in case of error.
        state = .idle(base: newBase)
        
        let element = try result.value
        
        return try await nextAndSave(
          candidate: element,
          nextTask: newBase.nextTask
        )
        
      case let .a((nil, newBase)):
        state = .idle(base: newBase)
        
        await sleepTask.value
        
        return candidate
        
      case .b:
        state = .fetching(nextTask)
        
        // No new element in cooldown period; return the candidate.
        return candidate
      }
    }
    
    private var sleepTask: Task<Void, Never> {
      let duration = duration, clock = clock
      
      let task =  Task {
        do {
          try await Task.sleep(duration, clock: clock)
        } catch {
          fatalError("Unexpected automatic task cancellation in detached task.")
        }
      }
      
      return task
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func debounce<ClockType>(
    _ duration: Duration,
    clock: ClockType
  ) -> AsyncDebounceSequence<Self, ClockType> {
    AsyncDebounceSequence(
      base: self,
      duration: duration,
      clock: clock
    )
  }
  
  public func debounce(
    _ duration: Duration
  ) -> AsyncDebounceSequence<Self, ContinuousClock> {
    AsyncDebounceSequence(
      base: self,
      duration: duration,
      clock: .continuous
    )
  }
}
