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
public struct AsyncMapResultSequence<
  Base: AsyncSequence,
  NewValue
>: AsyncSequence {
  public typealias Element = NewValue
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async -> Result<NewValue, Never>
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async -> Result<NewValue, Never>
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
    ) async -> Result<NewValue, Never>
    
    private var base: Base.AsyncIterator
    
    fileprivate init(
      base: Base.AsyncIterator,
      transform: @escaping (
        Result<Base.Element, Error>
      ) async -> Result<NewValue, Never>
    ) {
      self.base = base
      self.transform = transform
    }
    
    public mutating func next() async -> NewValue? {
      let wrappedResult = await Result.unwrap {
        try await base.next()
      }
      
      guard let result = wrappedResult else { return nil }
      
      return await transform(result).value
    }
  }
}

// Required for correct flatMapError/Result rethrows.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncMapResultSequence.AsyncIterator:
  _NonThrowingAsyncIteratorProtocol
{}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncThrowingMapResultSequence<
  Base: AsyncSequence,
  NewValue
>: AsyncSequence {
  public typealias Element = NewValue
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async throws -> Result<NewValue, Error>
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async throws -> Result<NewValue, Error>
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
    ) async throws -> Result<NewValue, Error>
    
    private var base: Base.AsyncIterator
    private var threwError = false
    
    fileprivate init(
      base: Base.AsyncIterator,
      transform: @escaping (
        Result<Base.Element, Error>
      ) async throws -> Result<NewValue, Error>
    ) {
      self.base = base
      self.transform = transform
    }
    
    public mutating func next() async throws -> NewValue? {
      guard !threwError else { return nil }
      
      let wrappedResult = await Result.unwrap {
        try await base.next()
      }
      
      guard let result = wrappedResult else { return nil }
      
      let transformedResult: Result<NewValue, Error>
      do {
        transformedResult = try await transform(result)
      } catch {
        threwError = true
        throw error
      }
      
      return try transformedResult.value
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func mapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async -> Result<NewValue, Never>
  ) -> AsyncMapResultSequence<Self, NewValue> {
    AsyncMapResultSequence(
      base: self,
      transform: transform
    )
  }
  
  @_disfavoredOverload
  public func mapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async throws -> Result<NewValue, Error>
  ) -> AsyncThrowingMapResultSequence<Self, NewValue> {
    AsyncThrowingMapResultSequence(
      base: self,
      transform: transform
    )
  }
  
  public func mapResult<NewValue>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async throws -> Result<NewValue, Never>
  ) -> AsyncThrowingMapResultSequence<Self, NewValue> {
    func mapNeverToError(_ never: Never) -> Error {}
    
    return mapResult { result -> Result<NewValue, Error> in
      try await transform(result).mapError(mapNeverToError)
    }
  }
}
