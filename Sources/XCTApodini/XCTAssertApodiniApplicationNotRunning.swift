//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 5/10/21.
//

import XCTest
import ApodiniUtils

/// Asserts that an expression leads to a runtime failure.
public func XCTAssertApodiniApplicationNotRunning(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let processesAtPort8080 = runShellCommand(.getProcessesAtPort(8080))
    if !processesAtPort8080.isEmpty {
        #if !os(Linux)
        XCTFail(
            """
            A web service is running at port 8080 after running the test case.
            All processes at port 8080 must be shut down after running the test case.
            
            \(message())
            """,
            file: file,
            line: line
        )
        #else
        print(
            """
            A web service is running at port 8080 after running the test case:
                \(processesAtPort8080)
            
            \(message())
            """
        )
        #endif
        runShellCommand(.killPort(8080))
    }
}
