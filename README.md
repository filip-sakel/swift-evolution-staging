# Async Operators

> **Note:** This package is a part of a Swift Evolution proposal for
  inclusion in the Swift standard library, and is not intended for use in
  production code at this time.

* Proposal: TBD
* Author: [Filip Sakel](https://github.com/filip-sakel)


## Introduction

This package adds additional `AsyncSequence` operators to take advantage of the protocol's error-handling and temporal features. 

```swift
import SENNNN_AsyncOperators

try await AsyncRepeated(1)
    .delay(.seconds(3))
    .drop(untilElementFrom: .one {
        // 6 -second sleep.
        try await Task.sleep(nanoseconds: 6_000_000_000)
    })
    .reduce(()) { _, _ in print("Got element") }
```


## Usage

To use this library in a Swift Package Manager project,
add the following to your `Package.swift` file's dependencies:

```swift
.package(
    url: "https://github.com/apple/swift-evolution-staging.git",
    .branch("SENNNN_AsyncOperators")),
```


