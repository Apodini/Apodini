//
//  XCTAssertRuntimeFailure.swift
//
//
//  Created by Paul Schmiedmayer on 1/2/21.
//


import XCTest
#if canImport(CwlPreconditionTesting) || canImport(CwlPosixPreconditionTesting)
#if canImport(CwlPreconditionTesting)
@_implementationOnly import CwlPreconditionTesting
#elseif canImport(CwlPosixPreconditionTesting)
@_implementationOnly import CwlPosixPreconditionTesting
#endif
// TODO CwlPOSIXPreconditioNTesting

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
    print("[WARN] XCTAssertRuntimeFailure unsupported!") // TODO remove
}
#endif
