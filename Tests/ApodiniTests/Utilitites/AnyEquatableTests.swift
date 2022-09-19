//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import ApodiniUtils


final class AnyEquatableTests: ApodiniTests {
    struct NonEquatable {}

    func testNonEquatableInput() throws {
        let lhs = "asdf"
        let rhs = NonEquatable()
        XCTAssertEqual(AnyEquatable.compare(lhs, rhs), .inputNotEquatable)
        XCTAssertEqual(AnyEquatable.compare(rhs, lhs), .inputNotEquatable)
        XCTAssertEqual(AnyEquatable.compare(rhs, rhs), .inputNotEquatable)
        XCTAssertEqual(AnyEquatable.compare(lhs, lhs), .equal)
    }

    func testNonMatchingTypes() {
        let result = AnyEquatable.compare("asdf", 3)
        XCTAssertEqual(result, .inputNotEquatable)
    }

    func testEquality() {
        let result = AnyEquatable.compare("asdf", "asdf")
        XCTAssert(result.isEqual)
        XCTAssert(!result.isNotEqual)
    }

    func testNonEquality() {
        let result = AnyEquatable.compare("asdf", "asdf2")
        XCTAssert(!result.isEqual)
        XCTAssert(result.isNotEqual)
    }
}
