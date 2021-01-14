//
// Created by Andi on 12.01.21.
//

import XCTest
@testable import Apodini

class OptionalTests: ApodiniTests {
    func testIsOptional() {
        /// A custom type
        struct Test {}

        XCTAssertEqual(isOptional(String.self), false)
        XCTAssertEqual(isOptional(Int.self), false)
        XCTAssertEqual(isOptional(Test.self), false)
        XCTAssertEqual(isOptional(Optional<Test>.self), true)
        XCTAssertEqual(isOptional(Optional<Test>.self), true)
        XCTAssertEqual(isOptional(String?.self), true)
        XCTAssertEqual(isOptional(String??.self), true)
        XCTAssertEqual(isOptional(String???.self), true)
        XCTAssertEqual(isOptional(Never.self), false)
    }
}
