//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
@testable import Apodini
import XCTest

final class HTTPConfigurationTests: ApodiniTests {
    func testDefaultValues() throws {
        let config = HTTPConfiguration()
        XCTAssertEqual(config.bindAddress, .init(address: "0.0.0.0", port: 80))
        XCTAssertEqual(config.hostname, .init(address: "localhost", port: 80))
        XCTAssertNil(config.tlsConfiguration)
    }
    
    func testSettingAddress() throws {
        HTTPConfiguration(bindAddress: .init(address: "1.2.3.4", port: 56))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .init(address: "1.2.3.4", port: 56))
    }
    
    func testCommandLineArguments() throws {
        HTTPConfiguration(bindAddress: .init(address: HTTPConfiguration.Defaults.bindAddress, port: 56))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .init(address: HTTPConfiguration.Defaults.bindAddress, port: 56))
    }
    
    func testCommandLineArguments1() throws {
        HTTPConfiguration(bindAddress: .init(address: "1.2.3.4"))
           .configure(app)

       XCTAssertNotNil(app.httpConfiguration.bindAddress)
       XCTAssertEqual(app.httpConfiguration.bindAddress, .init(address: "1.2.3.4", port: 80))
   }
    
    func testCommandLineArguments3() throws {
        HTTPConfiguration(bindAddress: try XCTUnwrap(.init("1.2.3.4:56")))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .init(address: "1.2.3.4", port: 56))
    }
}
