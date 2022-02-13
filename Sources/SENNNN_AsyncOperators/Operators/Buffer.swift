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
public struct AsyncBufferSequence<
  Base: AsyncSequence>: AsyncSequence
{
  /// A strategy that handles exhaustion of a buffer’s capacity.
  public enum BufferingPolicy {
    /// Continue to add to the buffer, without imposing a limit on the number
    /// of buffered elements.
    case unbounded

    /// When the buffer is full, discard the newly received element.
    ///
    /// This strategy enforces keeping at most the specified number of oldest
    /// values.
    case bufferingOldest(Int)

    /// When the buffer is full, discard the oldest element in the buffer.
    ///
    /// This strategy enforces keeping at most the specified number of newest
    /// values.
    case bufferingNewest(Int)
  }
  
  public typealias Element = Base.Element
  
  private let base: Base
  private let bufferingPolicy: BufferingPolicy
  private lazy var stream: AsyncThrowingStream<Element, Error> = {
    var streamBufferingPolicy: AsyncThrowingStream<
      Element,
      Error
    >.Continuation.BufferingPolicy {
      switch bufferingPolicy {
      case .unbounded:
        return .unbounded
        
      case let .bufferingOldest(count):
        return .bufferingOldest(count)
        
      case let .bufferingNewest(count):
        return .bufferingNewest(count)
      }
    }
    
    let base = base
    
    return AsyncThrowingStream<Element, Error>(
      bufferingPolicy: streamBufferingPolicy
    ) { continuation in
      Task {
        let resultSequence = base.mapResult(Result.success)
        for try await result in resultSequence {
          continuation.yield(with: result)
        }
      }
    }
  }()
  
  fileprivate init(
    base: Base,
    bufferingPolicy: BufferingPolicy,
    prefetch: Bool
  ) {
    self.base = base
    self.bufferingPolicy = bufferingPolicy
    
    // Start the stream fetching.
    if prefetch { _ = stream }
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    var copy = self
    return AsyncIterator(stream: copy.stream.makeAsyncIterator())
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var stream: AsyncThrowingStream<
      Element,
      Error
    >.AsyncIterator
    
    fileprivate init(
      stream: AsyncThrowingStream<
        Element,
        Error
      >.AsyncIterator
    ) {
      self.stream = stream
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await withUncheckedRethrows { try await stream.next() }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func buffer(
    policy: AsyncBufferSequence<
      Self
    >.BufferingPolicy = .unbounded,
    prefetch: Bool = false
  ) -> AsyncBufferSequence<Self> {
    AsyncBufferSequence(
      base: self,
      bufferingPolicy: policy,
      prefetch: prefetch
    )
  }
}
