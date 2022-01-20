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

/// An empty asynchronous sequence with the given element type.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct EmptyAsyncSequence<
  Element
>: AsyncSequence {
  /// Creates an empty, non-throwing asynchronous sequence with `Never`
  /// as its element type.
  public init(
    elementType: Element.Type = Element.self
  ) where Element == Never {}
  
  /// Creates an empty, non-throwing asynchronous sequence with the given
  /// element type.
  public init(
    elementType: Element.Type = Element.self
  ) {}

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator()
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    public mutating func next() async -> Element? {
      nil
    }
  }
}

/// An empty, throwing asynchronous sequence with the given element type.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct EmptyThrowingAsyncSequence<
  Element,
  Failure: Error
> {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EmptyThrowingAsyncSequence: AsyncSequence where
  Failure == Error
{
  /// Creates an empty, throwing asynchronous sequence with `Never` as its
  /// element type.
  public init(
    elementType: Element.Type = Element.self,
    failureType: Failure.Type = Failure.self
  ) where Element == Never {}
  
  /// Creates an empty, throwing asynchronous sequence with the given
  /// element type.
  public init(
    elementType: Element.Type = Element.self,
    failureType: Failure.Type = Failure.self
  ) {}

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator()
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    public mutating func next() async throws -> Element? {
      nil
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  /// Creates an empty, non-throwing asynchronous sequence with `Never`
  /// as its element type.
  public static func empty(
    elementType: Never.Type = Never.self,
    failureType: Never.Type = Never.self
  ) -> Self where
    Self == EmptyAsyncSequence<Never>
  {
    EmptyAsyncSequence()
  }
  
  /// Creates an empty, throwing asynchronous sequence with `Never` as its
  /// element type.
  @_disfavoredOverload
  public static func empty(
    elementType: Never.Type = Never.self,
    failureType: Error.Type = Error.self
  ) -> Self where
    Self == EmptyThrowingAsyncSequence<Never, Error>
  {
    EmptyThrowingAsyncSequence()
  }
  
  /// Creates an empty, non-throwing asynchronous sequence with the given
  /// element type.
  public static func empty<Element>(
    elementType: Element.Type = Element.self,
    failureType: Never.Type = Never.self
  ) -> Self where Self == EmptyAsyncSequence<Element> {
    EmptyAsyncSequence()
  }
  
  /// Creates an empty, throwing asynchronous sequence with the given
  /// element type.
  @_disfavoredOverload
  public static func empty<Element>(
    elementType: Element.Type = Element.self,
    failureType: Error.Type = Error.self
  ) -> Self where
    Self == EmptyThrowingAsyncSequence<Element, Error>
  {
    EmptyThrowingAsyncSequence()
  }
}
