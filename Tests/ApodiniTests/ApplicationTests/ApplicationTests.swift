//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
