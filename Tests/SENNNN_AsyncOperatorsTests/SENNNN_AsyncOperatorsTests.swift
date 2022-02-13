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

import XCTest
@testable import SENNNN_AsyncOperators

struct LazyClock: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Date
    func makeAsyncIterator() -> LazyClock { self }
    
    func next() async throws -> Date? {
        Date()
    }
}

final class SENNNN_PackageNameTests: XCTestCase {
    // TODO: Add tests.
    func testHey() async throws {
        // Delay
//        print(Date())
//
//        let result = try await LazyClock()
//            .delay(.seconds(1))
//            .reduce((), {
//                print($0, $1)
//            })
//
//        print(result)
        
        
        // Debounce
//        let sequence = [0, 0.5, 2, 0.5].async.map { d -> String in
//          try await Task.sleep(.seconds(d), clock: .continuous)
//          return "After \(d) second(s)"
//        }
//
//        for try await element in sequence {
//          print(element)
//        }
//        
//        print("-------------")
//
//        for try await element in sequence.debounce(.seconds(1)) {
//             print(element)
//        }
//
//        // After 2 second(s)
    }
}
