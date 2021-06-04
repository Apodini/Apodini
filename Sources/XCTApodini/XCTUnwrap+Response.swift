//
// Created by Andreas Bauer on 02.02.21.
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
