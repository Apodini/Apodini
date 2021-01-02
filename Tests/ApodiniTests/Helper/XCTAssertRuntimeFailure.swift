//
//  XCTAssertRuntimeFailure.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

#if canImport(CwlPreconditionTesting)
import CwlPreconditionTesting
#endif
#if canImportCwlPosixPreconditionTesting
import CwlPosixPreconditionTesting
#endif
import XCTest

func XCTAssertRuntimeFailure(
    _ expression: @escaping @autoclosure () -> Void,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line)
{
    guard catchBadInstruction(in: { expression() }) == nil else {
        return
    }
    XCTFail(message(), file: file, line: line)
}
