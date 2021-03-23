//
//  OptionalTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/14/21.
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
