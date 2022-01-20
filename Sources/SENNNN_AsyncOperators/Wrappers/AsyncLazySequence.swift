//
//  AsyncLazySequence.swift
//  
//
//  Created by Filippos Sakellariou on 1/11/22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
internal struct AsyncLazySequence<Base: Sequence>: AsyncSequence {
  public typealias Element = Base.Element
  
  public let sequence: Base

  @usableFromInline
  init(_ sequence: Base) {
    self.sequence = sequence
  }
  
  @inlinable
  public func makeAsyncIterator() -> AsyncIterator {
    return AsyncIterator(sequence.makeIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    @usableFromInline
    var iterator: Base.Iterator

    @usableFromInline
    init(_ iterator: Base.Iterator) {
      self.iterator = iterator
    }

    @inlinable
    public mutating func next() async -> Base.Element? {
      iterator.next()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Sequence {
  internal var `async`: AsyncLazySequence<Self> {
    AsyncLazySequence(self)
  }
}
