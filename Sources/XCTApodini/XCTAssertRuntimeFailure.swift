//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
#warning("""
    CwlPreconditionTesting currently seems to trigger a compiler bug in Xcode beta 3 with release builds.
    Try to uncomment the code below after each compiler release.
    
    Currently fails with:
    
    duplicate symbol '_NDR_record' in:
        /Users/***/Library/Developer/Xcode/DerivedData/apodini-gsirduylpqvqisgpfkhgicvjgsww/Build/Intermediates.noindex/CwlPreconditionTesting.build/Release/CwlPreconditionTesting.build/Objects-normal/x86_64/CwlBadInstructionException.o
        /Users/***/Library/Developer/Xcode/DerivedData/apodini-gsirduylpqvqisgpfkhgicvjgsww/Build/Intermediates.noindex/CwlPreconditionTesting.build/Release/CwlPreconditionTesting.build/Objects-normal/x86_64/CwlCatchBadInstruction.o
    ld: 1 duplicate symbol for architecture x86_64
""")
//#if canImport(CwlPreconditionTesting)
//@_implementationOnly import CwlPreconditionTesting
//
///// Asserts that an expression leads to a runtime failure.
//public func XCTAssertRuntimeFailure<T>(
//    _ expression: @escaping @autoclosure () -> T,
//    _ message: @autoclosure () -> String = "XCTAssertRuntimeFailure didn't fail as expected!",
//    file: StaticString = #filePath,
//    line: UInt = #line) {
//    guard catchBadInstruction(in: { _ = expression() }) == nil else {
//        return
//    }
//    XCTFail(message(), file: file, line: line)
//}
//#else
/// Empty implementation used for platforms that don't support `CwlPreconditionTesting`.
public func XCTAssertRuntimeFailure<T>(
    _ expression: @escaping @autoclosure () -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line) {
    // Empty implementation for Linux Tests
    print("[NOTICE] XCTAssertRuntimeFailure unsupported on this platform!")
}
//#endif
