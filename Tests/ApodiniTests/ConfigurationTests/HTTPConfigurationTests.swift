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
        HTTPConfiguration()
            .address(.hostname("1.2.3.4", port: 56))
            .configure(app)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }

    func testSettingSocket() throws {
        HTTPConfiguration()
            .address(.unixDomainSocket(path: "/tmp/test"))
            .configure(app)
        XCTAssertEqual(app.http.address, .unixDomainSocket(path: "/tmp/test"))
    }
    
    func testCommandLineArguments() throws {
        HTTPConfiguration(port: 56)
            .configure(app)
        XCTAssertEqual(app.http.address, .hostname("0.0.0.0", port: 56))
    }
    
    func testCommandLineArguments1() throws {
        HTTPConfiguration(hostname: "1.2.3.4")
           .configure(app)
       XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 8080))
   }
    
    func testCommandLineArguments2() throws {
        HTTPConfiguration(hostname: "1.2.3.4", port: 56)
            .configure(app)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }
    
    func testCommandLineArguments3() throws {
        HTTPConfiguration(bind: "1.2.3.4:56")
            .configure(app)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }
    
    func testCommandLineArguments4() throws {
        HTTPConfiguration(socketPath: "/tmp/test")
            .configure(app)
        XCTAssertEqual(app.http.address, .unixDomainSocket(path: "/tmp/test"))
    }
    
    func testCommandLineArgumentOverwrite() {
        HTTPConfiguration(bind: "1.2.3.4:56")
            .address(.hostname("7.8.9.10", port: 1112))
            .configure(app)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }
}
