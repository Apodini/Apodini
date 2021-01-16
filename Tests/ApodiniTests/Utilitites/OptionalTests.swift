//
//  OptionalTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/14/21.
//

import XCTest
@testable import Apodini


class OptionalTests: ApodiniTests {
    func testOptional() {
        let test: String? = "Paul"
        
        XCTAssertEqual(test.optionalInstance, "Paul")
        XCTAssert(type(of: test.optionalInstance) == type(of: test))
    }
}
