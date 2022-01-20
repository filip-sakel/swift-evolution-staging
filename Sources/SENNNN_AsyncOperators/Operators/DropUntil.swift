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

/// An asynchronous sequence which omits elements from the base sequence until
/// the other sequence emits its first element, after which it passes through
/// all remaining elements.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncDropUntilElementSequence<
  Base: AsyncSequence,
  Other: AsyncSequence
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let other: Other
  
  fileprivate init(
    base: Base,
    other: Other
  ) {
    self.base = base
    self.other = other
  }
  
  fileprivate typealias Proxy = AsyncDropWhileSequence<
    AsyncCompactMapSequence<
      AsyncMerge2Sequence<
        AsyncMapSequence<
          Base,
          Either<Base.Element, Other.Element>
        >,
        AsyncPrefixWhileSequence<
          AsyncMapSequence<
            Other,
            Either<Base.Element, Other.Element>
          >
        >
      >,
      Base.Element
    >
  >
  
  private var proxy: Proxy {
    typealias Box = Either<Base.Element, Other.Element>
    
    var receivedSecond = false
    
    // try! is used because of `prefix` bug.
    return merge(
      base.map(Box.a),
      try! other.map(Box.b)
        .prefix(while: { _ in !receivedSecond })
    )
    .compactMap { either -> Base.Element? in
      switch either {
      case let .a(element):
        return element
        
      case .b:
        receivedSecond = true
        return nil
      }
    }
    .drop(while: { _ in !receivedSecond })
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(proxy: proxy.makeAsyncIterator())
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var proxy: Proxy.AsyncIterator
    
    fileprivate init(proxy: Proxy.AsyncIterator) {
      self.proxy = proxy
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await proxy.next()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func drop<Other>(
    untilElementFrom other: Other
  ) -> AsyncDropUntilElementSequence<Self, Other> {
    AsyncDropUntilElementSequence(
      base: self,
      other: other
    )
  }
}

/// An asynchronous sequence which omits elements from the base sequence until
/// the other sequence emits its first error, after which it passes through
/// all remaining elements.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncDropUntilErrorSequence<
  Base: AsyncSequence,
  Other: AsyncSequence
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let other: Other
  
  fileprivate init(
    base: Base,
    other: Other
  ) {
    self.base = base
    self.other = other
  }
  
  fileprivate typealias Proxy = AsyncDropUntilElementSequence<
    Base,
    AsyncMapResultSequence<
      AsyncDropWhileSequence<Other>,
      Void
    >
  >
  
  private var proxy: Proxy {
    base.drop(
      untilElementFrom: other
        .drop(while: { _ in true })
        .mapResult { result -> Result<Void, Never> in
          guard case .failure = result else {
            fatalError("Expected drop to remove all elements.")
          }
          
          return .success(())
        }
    )
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(proxy: proxy.makeAsyncIterator())
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var proxy: Proxy.AsyncIterator
    
    fileprivate init(proxy: Proxy.AsyncIterator) {
      self.proxy = proxy
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await proxy.next()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func drop<Other>(
    untilErrorFrom other: Other
  ) -> AsyncDropUntilErrorSequence<Self, Other> {
    AsyncDropUntilErrorSequence(
      base: self,
      other: other
    )
  }
}

/// An asynchronous sequence which omits elements from the base sequence until
/// the other sequence emits its first result, which is an element or error, after which
/// it passes through all remaining elements.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncDropUntilResultSequence<
  Base: AsyncSequence,
  Other: AsyncSequence
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let other: Other
  
  fileprivate init(
    base: Base,
    other: Other
  ) {
    self.base = base
    self.other = other
  }
  
  fileprivate typealias Proxy = AsyncDropUntilElementSequence<
    Base,
    AsyncMapResultSequence<Other, Void>
  >
  
  private var proxy: Proxy {
    base.drop(
      untilElementFrom: other.mapResult { _ in .success(()) }
    )
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(proxy: proxy.makeAsyncIterator())
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var proxy: Proxy.AsyncIterator
    
    fileprivate init(proxy: Proxy.AsyncIterator) {
      self.proxy = proxy
    }
    
    public mutating func next() async rethrows -> Base.Element? {
      try await proxy.next()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func drop<Other>(
    untilResultFrom other: Other
  ) -> AsyncDropUntilResultSequence<Self, Other> {
    AsyncDropUntilResultSequence(
      base: self,
      other: other
    )
  }
}
