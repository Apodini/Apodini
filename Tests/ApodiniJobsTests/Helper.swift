//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import XCTest


// Helper method to test if a Job was correctly executed
func XCTAssertScheduling<T>(_ scheduled: Scheduled<T>) {
    var result = false
    var error: (any Error)?

    // Checks if Job was triggered
    scheduled.futureResult.whenSuccess { _  in result = true }
    // Checks if no error was thrown
    scheduled.futureResult.whenFailure { error = $0 }
    
    XCTAssertTrue(result)
    XCTAssertNil(error)
}
