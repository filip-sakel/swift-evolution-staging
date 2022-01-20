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
public struct AsyncCompactMapErrorSequence<
  Base: AsyncSequence
>: AsyncSequence {
  public typealias Element = Base.Element
  
  private let base: Base
  private let transform: (Error) -> Error?
  
  fileprivate init(
    base: Base,
    transform: @escaping (Error) -> Error?
  ) {
    self.base = base
    self.transform = transform
  }
  
  fileprivate typealias Proxy = AsyncThrowingCompactMapResultSequence<
    Base,
    Base.Element
  >
  
  private var proxy: Proxy {
    base.compactMapResult { result -> Result<Element, Error>? in
      do {
        return try .success(result.value)
      } catch {
        guard let newError = transform(error) else { return nil }
        return .failure(newError)
      }
    }
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: proxy.makeAsyncIterator()
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var base: Proxy.AsyncIterator
    
    fileprivate init(base: Proxy.AsyncIterator) {
      self.base = base
    }
    
    public mutating func next() async throws -> Base.Element? {
      try await base.next()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func compactMapError(
    _ transform: @escaping (Error) -> Error?
  ) -> AsyncCompactMapErrorSequence<Self> {
    AsyncCompactMapErrorSequence(
      base: self,
      transform:  transform
    )
  }
}
