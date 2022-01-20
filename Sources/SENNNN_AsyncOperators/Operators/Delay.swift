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
public struct AsyncDelaySequence<
  Base: AsyncSequence,
  ClockType: Clock
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let duration: Duration
  private let clock: ClockType
  private let uponRequest: Bool
  
  fileprivate init(
    base: Base,
    duration: Duration,
    clock: ClockType,
    uponRequest: Bool
  ) {
    self.base = base
    self.duration = duration
    self.clock = clock
    self.uponRequest = uponRequest
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: base.makeAsyncIterator(),
      duration: duration,
      clock: clock,
      uponRequest: uponRequest
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private let duration: Duration
    private let clock: ClockType
    private let uponRequest: Bool
    
    private var base: Base.AsyncIterator
    
    fileprivate init(
      base: Base.AsyncIterator,
      duration: Duration,
      clock: ClockType,
      uponRequest: Bool
    ) {
      self.base = base
      self.duration = duration
      self.clock = clock
      self.uponRequest = uponRequest
    }
    
    public mutating func next() async throws -> Base.Element? {
      if uponRequest {
        try await Task.sleep(duration, clock: clock)
        let element = try await base.next()
        
        return element
      } else {
        let result = await Result { try await base.next() }
        try await Task.sleep(duration, clock: clock)
        
        return try result.value
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func delay<ClockType: Clock>(
    _ duration: Duration,
    clock: ClockType,
    uponRequest: Bool = false
  ) -> AsyncDelaySequence<Self, ClockType> {
    AsyncDelaySequence(
      base: self,
      duration: duration,
      clock: clock,
      uponRequest: uponRequest
    )
  }
  
  public func delay(
    _ duration: Duration,
    uponRequest: Bool = false
  ) -> AsyncDelaySequence<Self, ContinuousClock> {
    delay(duration, clock: .continuous, uponRequest: uponRequest)
  }
}
