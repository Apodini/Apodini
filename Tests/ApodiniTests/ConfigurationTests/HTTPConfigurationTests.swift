//
//  HTTPConfigurationTests.swift
//
//
//  Created by Tim Gymnich on 14.1.21.
//

@testable import Apodini
import XCTest

final class HTTPConfigurationTests: ApodiniTests {
    func testSettingAddress() throws {
        HTTPConfiguration()
            .address(.hostname("1.2.3.4", port: 56))
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }

    func testCommandLineArguments() throws {
        CommandLine.arguments += ["--hostname", "1.2.3.4", "--port", "56"]
        HTTPConfiguration()
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }
}
