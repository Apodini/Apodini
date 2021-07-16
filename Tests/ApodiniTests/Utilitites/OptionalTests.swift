//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import XCTest
@testable import Apodini
import ApodiniUtils


class OptionalTests: ApodiniTests {
    func testOptional() {
        let test: String? = "Paul"
        
        XCTAssertEqual(test.optionalInstance, "Paul")
        XCTAssert(type(of: test.optionalInstance) == type(of: test))
    }

    func testIsNil() {
        struct Wrapper<Type> {
            let value: Type
            var valueNil: Bool {
                // calls isNil using the generically typed value
                isNil(value)
            }
        }

        let nonNil = Wrapper(value: "asdf")
        let optionalNonNil = Wrapper<String?>(value: "asdf")
        let optionalNil = Wrapper<String?>(value: nil)

        XCTAssertEqual(nonNil.valueNil, false)
        XCTAssertEqual(optionalNonNil.valueNil, false)
        XCTAssertEqual(optionalNil.valueNil, true)
    }
}
