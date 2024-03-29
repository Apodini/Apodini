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
    func testSettingAddress() throws {
        HTTPConfiguration(bindAddress: .interface("1.2.3.4", port: 56))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .interface("1.2.3.4", port: 56))
    }

    func testSettingSocket() throws {
        HTTPConfiguration(bindAddress: .unixDomainSocket(path: "/tmp/test"))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .unixDomainSocket(path: "/tmp/test"))
    }
    
    func testCommandLineArguments() throws {
        HTTPConfiguration(bindAddress: .interface(HTTPConfiguration.Defaults.bindAddress, port: 56))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .interface(HTTPConfiguration.Defaults.bindAddress, port: 56))
    }
    
    func testCommandLineArguments1() throws {
        HTTPConfiguration(bindAddress: .interface("1.2.3.4"))
           .configure(app)

       XCTAssertNotNil(app.httpConfiguration.bindAddress)
       XCTAssertEqual(app.httpConfiguration.bindAddress, .interface("1.2.3.4", port: 80))
   }
    
    func testCommandLineArguments3() throws {
        HTTPConfiguration(bindAddress: .address("1.2.3.4:56"))
            .configure(app)

        XCTAssertNotNil(app.httpConfiguration.bindAddress)
        XCTAssertEqual(app.httpConfiguration.bindAddress, .interface("1.2.3.4", port: 56))
    }
}
