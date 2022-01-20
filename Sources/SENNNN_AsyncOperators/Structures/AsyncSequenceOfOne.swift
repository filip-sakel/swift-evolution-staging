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

/// An asynchronous sequence that contains only the given lazily-calculated
/// element.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncSequenceOfOne<Element>: AsyncSequence {
  private let makeElement: () async -> Element
  
  /// Creates a non-throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  public init(_ makeElement: @escaping () async -> Element) {
    self.makeElement = makeElement
  }
  
  /// Creates a non-throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  public init(_ element: @autoclosure @escaping () -> Element) {
    self.init(element)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(makeElement: makeElement)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private let makeElement: () async -> Element
    private var finished = false
    
    fileprivate init(makeElement: @escaping () async -> Element) {
      self.makeElement = makeElement
    }
    
    public mutating func next() async -> Element? {
      guard !finished else { return nil }
      
      defer { finished = true }
      
      return await makeElement()
    }
  }
}

/// A throwing asynchronous sequence that contains only the given lazily-calculated
/// element.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncThrowingSequenceOfOne<
  Element,
  Failure: Error
> {
  private let makeElement: () async throws -> Element
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncThrowingSequenceOfOne: AsyncSequence where
  Failure == Error
{
  /// Creates a throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  public init(
    _ makeElement: @escaping () async throws -> Element
  ) {
    self.makeElement = makeElement
  }
  
  /// Creates a throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  public init(
    _ element: @autoclosure @escaping () throws -> Element
  ) {
    self.init(element)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(makeElement: makeElement)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private let makeElement: () async throws -> Element
    private var finished = false
    
    fileprivate init(
      makeElement: @escaping () async throws -> Element
    ) {
      self.makeElement = makeElement
    }
    
    public mutating func next() async throws -> Element? {
      guard !finished else { return nil }
      
      defer { finished = true }
      
      return try await makeElement()
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  /// Creates a non-throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  public static func one<Element>(
    _ makeElement: @escaping () async -> Element
  ) -> Self where Self == AsyncSequenceOfOne<Element> {
    AsyncSequenceOfOne(makeElement)
  }
  
  /// Creates a throwing asynchronous sequence that contains only
  /// the given lazily-calculated element.
  @_disfavoredOverload
  public static func one<Element>(
    _ makeElement: @escaping () async throws -> Element
  ) -> Self where
    Self == AsyncThrowingSequenceOfOne<Element, Error>
  {
    AsyncThrowingSequenceOfOne(makeElement)
  }
}
