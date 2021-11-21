//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import ApodiniUtils

/// Asserts that an expression leads to a runtime failure.
public func XCTAssertApodiniApplicationNotRunning(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let processesAtPort80 = runShellCommand(.getProcessesAtPort(80))
    if !processesAtPort80.isEmpty {
        #if !os(Linux)
        XCTFail(
            """
            A web service is running at port 80 after running the test case.
            All processes at port 80 must be shut down after running the test case.
            
            \(message())
            """,
            file: file,
            line: line
        )
        #else
        print(
            """
            A web service is running at port 80 after running the test case:
                \(processesAtPort80)
            
            \(message())
            """
        )
        #endif
        runShellCommand(.killPort(80))
    }
}
