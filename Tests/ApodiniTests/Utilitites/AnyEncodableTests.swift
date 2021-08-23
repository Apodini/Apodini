//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import ApodiniUtils

final class AnyEncodableTests: ApodiniTests {
    struct NonEquatable {
        var test: String
    }

    func testLHSNonEquatable() throws {
        let result = AnyEquatable.compare("asdf", NonEquatable(test: "asdf"))
        XCTAssertEqual(result, .notEquatable)
    }

    func testNonMatchingTypes() {
        let result = AnyEquatable.compare("asdf", 3)
        XCTAssertEqual(result, .nonMatchingTypes)
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
