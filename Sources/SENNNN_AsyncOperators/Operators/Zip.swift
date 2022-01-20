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

/// An asynchronous sequence of pairs built out of two underlying sequences.
///
/// An error that occurs in either of the underlying sequences is simply
/// forwarded, preventing the construction of the corresponding pair.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncZip2Sequence<
  Sequence1: AsyncSequence,
  Sequence2: AsyncSequence
>: AsyncSequence {
  public typealias Element = (Sequence1.Element, Sequence2.Element)
  
  private let sequence1: Sequence1
  private let sequence2: Sequence2
  
  public init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
    self.sequence1 = sequence1
    self.sequence2 = sequence2
  }
  
  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(
      iterator1: sequence1.makeAsyncIterator(),
      iterator2: sequence2.makeAsyncIterator()
    )
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    private var iterator1: Sequence1.AsyncIterator
    private var iterator2: Sequence2.AsyncIterator
    
    fileprivate init(
      iterator1: Sequence1.AsyncIterator,
      iterator2: Sequence2.AsyncIterator
    ) {
      self.iterator1 = iterator1
      self.iterator2 = iterator2
    }
  
    public mutating func next() async rethrows -> Element? {
      let iterator1 = iterator1, iterator2 = iterator2
      
      typealias GroupResult = Either<
        (
          Result<Sequence1.Element, Error>?,
          Sequence1.AsyncIterator
        ),
        (
          Result<Sequence2.Element, Error>?,
          Sequence2.AsyncIterator
        )
      >
      
      return try await withThrowingTaskGroup(
        of: GroupResult.self,
        returning: (Sequence1.Element, Sequence2.Element)?.self
      ) { group in
        // Task groups return results so that the iterators can
        // be updated.
        group.addTask {
          var iteratorCopy = iterator1
          
          let result = await Result.unwrap {
              try await iteratorCopy.next()
          }
          
          return Either.a((result, iteratorCopy))
        }
        group.addTask {
          var iteratorCopy = iterator2
          
          let result = await Result.unwrap {
              try await iteratorCopy.next()
          }
          
          return Either.b((result, iteratorCopy))
        }
        
        var element1: Sequence1.Element? = nil
        var element2: Sequence2.Element? = nil
        
        // The error of the first-to-throw sequence. Errors are
        // caught to let both iterators finish and update self.
        var caughtError: Error? = nil
        
        // Groups don't actually throw, but a throwing task group
        // is used to forward errors in this stage.
        for try await eitherResult in group {
          switch eitherResult {
          case let .a((wrappedResult, iterator1)):
            self.iterator1 = iterator1
            
            do {
              guard let result = wrappedResult else { return nil }
              element1 = try result.value
            } catch where caughtError == nil {
              caughtError = error
            }
            
          case let .b((wrappedResult, iterator2)):
            self.iterator2 = iterator2
            
            do {
              guard let result = wrappedResult else { return nil }
              element2 = try result.value
            } catch where caughtError == nil {
              caughtError = error
            }
          }
        }
        
        if let caughtError = caughtError { throw caughtError }
        
        // Can force-unwrap since the for-loop returns on a nil of
        // the underlying sequences and thrown errors are handled
        // above.
        return (element1!, element2!)
      }
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func zip<Sequence1, Sequence2>(
  _ sequence1: Sequence1,
  _ sequence2: Sequence2
) -> AsyncZip2Sequence<Sequence1, Sequence2> {
  AsyncZip2Sequence(sequence1, sequence2)
}
