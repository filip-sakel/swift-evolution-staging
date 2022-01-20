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
public struct AsyncCompactMapResultSequence<
  Base: AsyncSequence,
  NewValue
>: AsyncSequence {
  public typealias Element = NewValue
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async -> Result<NewValue, Never>?
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async -> Result<NewValue, Never>?
  ) {
    self.base = base
    self.transform = transform
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: base.makeAsyncIterator(),
      transform: transform
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private let transform: (
      Result<Base.Element, Error>
    ) async -> Result<NewValue, Never>?
    
    private var base: Base.AsyncIterator
    
    fileprivate init(
      base: Base.AsyncIterator,
      transform: @escaping (
        Result<Base.Element, Error>
      ) async -> Result<NewValue, Never>?
    ) {
      self.base = base
      self.transform = transform
    }
    
    public mutating func next() async -> NewValue? {
      // The result of the underlying sequence.
      let wrappedResult = await Result.unwrap {
        try await base.next()
      }
      
      // Base emitted nil.
      guard let result = wrappedResult else { return nil }
      
      // The transformed value is nil, so we skip.
      guard let value = await transform(result)?.value else {
        return await next()
      }

      return value
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncThrowingCompactMapResultSequence<
  Base: AsyncSequence,
  NewValue
>: AsyncSequence {
  public typealias Element = NewValue
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async throws -> Result<NewValue, Error>?
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async throws -> Result<NewValue, Error>?
  ) {
    self.base = base
    self.transform = transform
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: base.makeAsyncIterator(),
      transform: transform
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private let transform: (
      Result<Base.Element, Error>
    ) async throws -> Result<NewValue, Error>?
    
    private var base: Base.AsyncIterator
    private var threwError = false
    
    fileprivate init(
      base: Base.AsyncIterator,
      transform: @escaping (
        Result<Base.Element, Error>
      ) async throws -> Result<NewValue, Error>?
    ) {
      self.base = base
      self.transform = transform
    }
    
    public mutating func next() async throws -> NewValue? {
      guard !threwError else { return nil }
      
      // The result of the underlying sequence.
      let wrappedResult = await Result.unwrap {
        try await base.next()
      }
      
      // Base emitted nil.
      guard let result = wrappedResult else { return nil }
      
      let transformedResult: Result<NewValue, Error>?
      do {
        transformedResult = try await transform(result)
      } catch {
        threwError = true
        throw error
      }
      
      // The transformed value is nil, so we skip.
      guard let value = try transformedResult?.value else {
        return try await next()
      }
      
      return value
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func compactMapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async -> Result<NewValue, Never>?
  ) -> AsyncCompactMapResultSequence<Self, NewValue> {
    AsyncCompactMapResultSequence(
      base: self,
      transform: transform
    )
  }
  
  @_disfavoredOverload
  public func compactMapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async throws -> Result<NewValue, Error>?
  ) -> AsyncThrowingCompactMapResultSequence<Self, NewValue> {
    AsyncThrowingCompactMapResultSequence(
      base: self,
      transform: transform
    )
  }
  
  public func compactMapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async throws -> Result<NewValue, Never>?
  ) -> AsyncThrowingCompactMapResultSequence<Self, NewValue> {
    func mapNeverToError(_ never: Never) -> Error {}
    
    return compactMapResult { result in
      try await transform(result)?.mapError(mapNeverToError)
    }
  }
}
