//
// Created by Andreas Bauer on 23.08.21.
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
