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

// FIXME: To be removed in final implementation.

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct Duration: Sendable {
  fileprivate let nanoseconds: UInt64
  
  static func seconds(_ seconds: Int) -> Duration {
    Duration(nanoseconds: UInt64(seconds * 1_000_000_000))
  }
  
  static func seconds(_ seconds: Double) -> Duration {
    Duration(nanoseconds: UInt64(seconds) * 1_000_000_000)
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task where Success == Never, Failure == Never {
  internal static func sleep<ClockType: Clock>(
    _ duration: Duration,
    clock: ClockType
  ) async throws {
    try await Task.sleep(
      nanoseconds: duration.nanoseconds
    )
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol Clock: Sendable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct ContinuousClock: Clock {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Clock where Self == ContinuousClock {
  public static var continuous: Self {
    ContinuousClock()
  }
}
