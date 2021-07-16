//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import XCTest
import Apodini

/// Overload for force unwrapping `Response` types.
public func XCTUnwrap<T: Encodable>(
    _ expression: @autoclosure () throws -> Response<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T {
    try XCTUnwrap(try expression().content, message(), file: file, line: line)
}
