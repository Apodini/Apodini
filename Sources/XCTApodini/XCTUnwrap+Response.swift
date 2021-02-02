//
// Created by Andreas Bauer on 02.02.21.
//

import XCTest
import Apodini

func XCTUnwrap<T: Encodable>(
    _ expression: @autoclosure () throws -> Response<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T {
    let result: T?
    switch try expression() {
    case let .final(element),
        let .send(element):
        result = element
    default:
        result = nil
    }

    return try XCTUnwrap(result, message: message, file: file, line: line)
}
