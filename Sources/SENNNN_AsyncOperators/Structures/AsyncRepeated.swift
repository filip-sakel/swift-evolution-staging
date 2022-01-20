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

/// An asynchronous sequence that repeats the given lazily-calculated element.
/// If the count is nil, the element is repeated forever.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncRepeated<Element>: AsyncSequence {
  private let count: Int?
  private let makeElement: () async -> Element

  /// Creates an `AsyncRepeated` sequence that repeats the given, lazily evaluated
  /// closure.
  ///
  /// - Precondition: `count` must be non-negative.
  public init(
    count: Int? = nil,
    _ makeElement: @escaping () async -> Element
  ) {
    precondition(
      (count ?? .max) >= 0,
      "Expected non-negative count."
    )
      
    self.count = count
    self.makeElement = makeElement
  }
  
  /// Creates an `AsyncRepeated` sequence that repeats the given, lazily evaluated
  /// element.
  ///
  /// - Precondition: `count` must be non-negative.
  public init(
    count: Int? = nil,
    _ element: @autoclosure @escaping () -> Element
  ) {
    self.init(count: count, element)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(makeElement: makeElement, count: count)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private let makeElement: () async -> Element
    
    private var count: Int?
    private var element: Element? = nil
    
    fileprivate init(
      makeElement: @escaping () async -> Element,
      count: Int? = nil
    ) {
      self.makeElement = makeElement
      self.count = count
    }
  
    public mutating func next() async -> Element? {
      guard count != 0 else { return nil }
      defer { count = count.map { $0 - 1 } }
      
      guard let element = element else {
        let element = await makeElement()
        self.element = element
        
        return element
      }

      return element
    }
  }
}

/// A throwing asynchronous sequence that repeats the given lazily-calculated
/// element. If the count is nil, the element is repeated forever. If the given element can't
/// be produced due to an error, that error will be repeated.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncThrowingRepeated<
  Element,
  Failure: Error
> {
  private let count: Int?
  private let makeElement: () async throws -> Element
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncThrowingRepeated: AsyncSequence where
  Failure == Error
{
  /// Creates an `AsyncRepeated` sequence that repeats the given, lazily evaluated
  /// closure.
  ///
  /// - Precondition: `count` must be non-negative.
  public init(
    count: Int? = nil,
    _ makeElement: @escaping () async throws -> Element
  ) where Failure == Error {
    precondition(
      (count ?? .max) >= 0,
      "Expected non-negative count."
    )
    
    self.makeElement = makeElement
    self.count = count
  }
  
  /// Creates an `AsyncRepeated` sequence that repeats the given, lazily evaluated
  /// element.
  ///
  /// - Precondition: `count` must be non-negative.
  public init(
    count: Int? = nil,
    _ element: @autoclosure @escaping () throws -> Element
  ) where Failure == Error {
    self.init(count: count, element)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(makeElement: makeElement, count: count)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private let makeElement: () async throws -> Element
    
    private var count: Int?
    private var element: Result<Element, Error>? = nil
    
    fileprivate init(
      makeElement: @escaping () async throws -> Element,
      count: Int? = nil
    ) {
      self.makeElement = makeElement
      self.count = count
    }
    
    public mutating func next() async throws -> Element? {
      guard count != 0 else { return nil }
      defer { count = count.map { $0 - 1 } }
      
      guard let element = element else {
        let element: Result<Element, Error>
        defer { self.element = element }
        
        do {
          element = try .success(await makeElement())
        } catch {
          element = .failure(error)
        }
        
        return try element.value
      }

      return try element.value
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
  /// Creates an asynchronous sequence that repeats the given lazily-calculated
  /// element. If the count is nil, the element is repeated forever.
  ///
  /// - Precondition: `count` must be non-negative.
  public static func repeated<Element>(
    count: Int? = nil,
    _ makeElement: @escaping () async -> Element
  ) -> Self where Self == AsyncRepeated<Element> {
    AsyncRepeated(count: count, makeElement)
  }
  
  /// Creates a throwing asynchronous sequence that repeats the given lazily-calculated
  /// element. If the count is nil, the element is repeated forever. If the given element can't
  /// be produced due to an error, that error will be repeated.
  ///
  /// - Precondition: `count` must be non-negative.
  @_disfavoredOverload
  public static func repeated<Element>(
    count: Int? = nil,
    _ makeElement: @escaping () async throws -> Element
  ) -> Self where Self == AsyncThrowingRepeated<Element, Error> {
    AsyncThrowingRepeated(count: count, makeElement)
  }
}
