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

        let pipe = Pipe()
        process.standardOutput = pipe
        
        let timeoutExpectation = XCTestExpectation(description: "Timeout Expectation")
        DispatchQueue(label: "TestTimeOut").asyncAfter(deadline: .now() + 5.0) {
            timeoutExpectation.fulfill()
        }
        
        try process.run()
        
        wait(for: [timeoutExpectation], timeout: 6.0)
        
        guard process.isRunning else {
            XCTFail("The server terminated during the setup: \(process.terminationStatus)")
            return
        }
        
        process.terminate()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            XCTFail("Could not parse the startup output of the web service")
            return
        }
        
        print(output)
        
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
