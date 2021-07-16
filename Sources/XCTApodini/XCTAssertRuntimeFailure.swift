//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
#if canImport(CwlPreconditionTesting)
@_implementationOnly import CwlPreconditionTesting

/// Asserts that an expression leads to a runtime failure.
public func XCTAssertRuntimeFailure<T>(
    _ expression: @escaping @autoclosure () -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line) {
    guard catchBadInstruction(in: { _ = expression() }) == nil else {
        return
    }
    XCTFail(message(), file: file, line: line)
}
#else
/// Empty implementation used for plattforms that don' support `CwlPreconditionTesting`.
public func XCTAssertRuntimeFailure<T>(
    _ expression: @escaping @autoclosure () -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line) {
    // Empty implementation for Linux Tests
    print("[NOTICE] XCTAssertRuntimeFailure unsupported on this platform!")
}
#endif
