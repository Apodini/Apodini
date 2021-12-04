//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import class Foundation.Bundle


final class DownloadsTests: XCTestCase {
    func testExample() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let testWebServiceBinary = productsDirectory.appendingPathComponent("TestWebService")

        let process = Process()
        process.executableURL = testWebServiceBinary
        
        let pipe = Pipe()
        process.standardError = pipe
        
        var timeoutExpectation = XCTestExpectation(description: "Timeout Expectation")
        DispatchQueue(label: "TestTimeOut").asyncAfter(deadline: .now() + 4.0) {
            timeoutExpectation.fulfill()
        }
        
        try process.run()
        
        wait(for: [timeoutExpectation], timeout: 5.0)
        
        guard process.isRunning else {
            XCTFail("The server terminated during the setup: \(process.terminationStatus). stderr: \(String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!)")
            return
        }
        
        timeoutExpectation = XCTestExpectation(description: "Timeout Expectation")
        DispatchQueue(label: "TestTimeOut").asyncAfter(deadline: .now() + 1.0) {
            timeoutExpectation.fulfill()
        }
        
        process.terminate()
        
        wait(for: [timeoutExpectation], timeout: 2.0)
        
        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                XCTFail("Could not parse the startup output of the web service")
                return
            }
            
            XCTFail(
                """
                The process did not terminate with a success response code:
                \(output)
                """
            )
            return
        }
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
}
