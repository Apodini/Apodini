//
//  ApplicationTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/17/21.
//

import XCTest
import Apodini


class ApplicationTests: XCTestCase {
    func testLogger() {
        let logger = Application.logger
        #if DEBUG
        XCTAssertEqual(logger.logLevel, .debug)
        #endif
        logger.debug("ApplicationTests complete")
    }
}
