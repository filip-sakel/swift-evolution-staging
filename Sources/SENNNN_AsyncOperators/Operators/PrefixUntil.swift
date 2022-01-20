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

/// An asynchronous sequence containing the initial, consecutive elements
/// gathered from the base sequence before the other sequence emits its first
/// element.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncPrefixUntilElementSequence<
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
  
  fileprivate typealias Proxy = AsyncPrefixWhileSequence<
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
    return try! merge(
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
    .prefix(while: { _ in !receivedSecond })
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
  public func prefix<Other>(
    untilElementFrom other: Other
  ) -> AsyncPrefixUntilElementSequence<Self, Other> {
    AsyncPrefixUntilElementSequence(
      base: self,
      other: other
    )
  }
}

/// An asynchronous sequence containing the initial, consecutive elements
/// gathered from the base sequence before the other sequence emits its first
/// error.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncPrefixUntilErrorSequence<
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
  
  fileprivate typealias Proxy = AsyncPrefixUntilElementSequence<
    Base,
    AsyncMapResultSequence<
      AsyncDropWhileSequence<Other>,
      Void
    >
  >
  
  private var proxy: Proxy {
    base.prefix(
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
  public func prefix<Other>(
    untilErrorFrom other: Other
  ) -> AsyncPrefixUntilErrorSequence<Self, Other> {
    AsyncPrefixUntilErrorSequence(
      base: self,
      other: other
    )
  }
}

/// An asynchronous sequence containing the initial, consecutive elements
/// gathered from the base sequence before the other sequence emits its first
/// result, which is an element or error.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncPrefixUntilResultSequence<
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
  
  fileprivate typealias Proxy = AsyncPrefixUntilElementSequence<
    Base,
    AsyncMapResultSequence<Other, Void>
  >
  
  private var proxy: Proxy {
    base.prefix(
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
  public func prefix<Other>(
    untilResultFrom other: Other
  ) -> AsyncPrefixUntilResultSequence<Self, Other> {
    AsyncPrefixUntilResultSequence(
      base: self,
      other: other
    )
  }
}
