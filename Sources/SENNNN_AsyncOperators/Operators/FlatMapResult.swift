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
public struct AsyncFlatMapResultSequence<
  Base: AsyncSequence,
  SegmentOfResult: AsyncSequence
>: AsyncSequence {
  public typealias Element = SegmentOfResult.Element
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async -> SegmentOfResult
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async -> SegmentOfResult
  ) {
    self.base = base
    self.transform = transform
  }
  
  public typealias AsyncIterator = AsyncFlatMapResultIterator<
    Base.Element,
    AsyncMapResultSequence<Base, Result<Base.Element, Error>>,
    SegmentOfResult
  >
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      base: base.mapResult(Result.success).makeAsyncIterator(),
      transform: transform
    )
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncFlatMapResultIterator<
  NewValue,
  WrappedBase: AsyncSequence,
  SegmentOfResult: AsyncSequence
>: AsyncIteratorProtocol where
  WrappedBase.AsyncIterator: _NonThrowingAsyncIteratorProtocol,
  WrappedBase.Element == Result<NewValue, Error>
{
  public typealias Element = SegmentOfResult.Element
  private typealias SubIterator = SegmentOfResult.AsyncIterator
  
  private let transform: (
    Result<NewValue, Error>
  ) async -> SegmentOfResult
  
  private var base: WrappedBase.AsyncIterator
  private var currentIterator: SubIterator? = nil
  
  fileprivate init(
    base: WrappedBase.AsyncIterator,
    transform: @escaping (
      Result<NewValue, Error>
    ) async -> SegmentOfResult
  ) {
    self.base = base
    self.transform = transform
  }
  
  public mutating func next() async rethrows -> Element? {
    guard
      currentIterator != nil,
      let element = try await currentIterator!.next()
    else {
      let wrappedResult = await base.next()
      
      guard let result = wrappedResult else { return nil }
      
      let transformedResult = await transform(result)
      currentIterator = transformedResult.makeAsyncIterator()
      
      return try await next()
    }
    
    return element
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncThrowingFlatMapResultSequence<
  Base: AsyncSequence,
  SegmentOfResult: AsyncSequence
>: AsyncSequence {
  public typealias Element = SegmentOfResult.Element
  
  private let base: Base
  private let transform: (
    Result<Base.Element, Error>
  ) async throws -> SegmentOfResult
  
  fileprivate init(
    base: Base,
    transform: @escaping (
      Result<Base.Element, Error>
    ) async throws -> SegmentOfResult
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
    private typealias SubIterator = SegmentOfResult.AsyncIterator
    
    private let transform: (
      Result<Base.Element, Error>
    ) async throws -> SegmentOfResult
    
    private var base: Base.AsyncIterator
    private var currentIterator: SubIterator? = nil
    private var threwError = false
    
    fileprivate init(
      base: Base.AsyncIterator,
      transform: @escaping (
        Result<Base.Element, Error>
      ) async throws -> SegmentOfResult
    ) {
      self.base = base
      self.transform = transform
    }
    
    public mutating func next() async throws -> Element? {
      guard !threwError else { return nil }
      
      guard
        currentIterator != nil,
        let element = try await currentIterator!.next()
      else {
        let wrappedResult = await Result.unwrap {
          try await base.next()
        }
        
        guard let result = wrappedResult else { return nil }
        
        do {
          let transformedResult = try await transform(result)
          currentIterator = transformedResult.makeAsyncIterator()
        } catch {
          threwError = true
          throw error
        }
        
        return try await next()
      }
      
      return element
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  public func flatMapResult<SegmentOfResult>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async -> SegmentOfResult
  ) -> AsyncFlatMapResultSequence<Self, SegmentOfResult> {
    AsyncFlatMapResultSequence(
      base: self,
      transform: transform
    )
  }
  
  public func flatMapResult<SegmentOfResult>(
    _ transform: @escaping (
      Result<Element, Error>
    ) async throws -> SegmentOfResult
  ) -> AsyncThrowingFlatMapResultSequence<Self, SegmentOfResult> {
    AsyncThrowingFlatMapResultSequence(
      base: self,
      transform: transform
    )
  }
}
