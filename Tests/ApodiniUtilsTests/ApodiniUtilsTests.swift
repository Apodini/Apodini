//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import ApodiniUtils


class ApodiniUtilsTests: XCTestCase {
    func testStringWhitespaceTrimming() {
        XCTAssertEqual("Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingTrailingWhitespace(), " Hello World")
        XCTAssertEqual("\tHello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" \t Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual("Hello World\t".trimmingTrailingWhitespace(), "Hello World")
        XCTAssertEqual("Hello\tWorld".trimmingLeadingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("Hello\tWorld".trimmingTrailingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("\tHello World\t".trimmingLeadingAndTrailingWhitespace(), "Hello World")
    }
    
    
    func testCreateStringFromInt8Tuple() throws {
        let cString = strdup("abcd")!
        defer { free(cString) }
        
        XCTAssertEqual("abcd", try XCTUnwrap(String.createFromInt8Tuple(
            (cString[0], cString[1], cString[2], cString[3])
        )))
    }
}
