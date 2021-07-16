//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest

#if canImport(XCTAssertCrash)
@_implementationOnly import XCTAssertCrash

/// Asserts that an expression leads to a runtime failure.
public func XCTAssertRuntimeFailure<T>(
    _ expression: @escaping @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "XCTAssertRuntimeFailure didn't fail as expected!",
    file: StaticString = #filePath,
    line: UInt = #line) {
    XCTAssertCrash(
        try! expression(),
        message(),
        file: file,
        line: line,
        skipIfBeingDebugged: false)
}
#else
/// Empty implementation used for platforms that don't support `CwlPreconditionTesting`.
public func XCTAssertRuntimeFailure<T>(
    _ expression: @escaping @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line) {
    // Empty implementation for Linux Tests
    print("[NOTICE] XCTAssertRuntimeFailure unsupported on this platform!")
}
#endif
