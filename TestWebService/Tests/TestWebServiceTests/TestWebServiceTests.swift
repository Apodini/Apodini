//
//  TestWebServiceTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/22/21.
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
        
        var timeoutExpectation = XCTestExpectation(description: "Timeout Expectation")
        DispatchQueue(label: "TestTimeOut").asyncAfter(deadline: .now() + 2.0) {
            timeoutExpectation.fulfill()
        }
        
        try process.run()
        
        wait(for: [timeoutExpectation], timeout: 2.5)
        
        guard process.isRunning else {
            XCTFail("The server terminated during the setup: \(process.terminationStatus)")
            return
        }
        
        timeoutExpectation = XCTestExpectation(description: "Timeout Expectation")
        DispatchQueue(label: "TestTimeOut").asyncAfter(deadline: .now() + 0.5) {
            timeoutExpectation.fulfill()
        }
        
        process.terminate()
        
        wait(for: [timeoutExpectation], timeout: 1.0)
        
        XCTAssertEqual(process.terminationStatus, 0)
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
