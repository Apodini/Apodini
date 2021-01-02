//
//  XCTAssertRuntimeFailure.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//


import XCTest
#if canImport(CwlPreconditionTesting)
import CwlPreconditionTesting

func XCTAssertRuntimeFailure<T>(
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
func XCTAssertRuntimeFailure(
    _ expression: @escaping @autoclosure () -> Void,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line) {
    // Empty implementation for Linux Tests
}
#endif
