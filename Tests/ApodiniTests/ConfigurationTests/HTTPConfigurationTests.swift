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

    func testSettingSocket() throws {
        HTTPConfiguration()
            .address(.unixDomainSocket(path: "/tmp/test"))
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .unixDomainSocket(path: "/tmp/test"))
    }

    func testCommandLineArguments1() throws {
        HTTPConfiguration(arguments: CommandLine.arguments + ["--hostname", "1.2.3.4", "--port", "56"])
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }

    func testCommandLineArguments2() throws {
        HTTPConfiguration(arguments: CommandLine.arguments + ["--bind", "1.2.3.4:56"])
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .hostname("1.2.3.4", port: 56))
    }

    func testCommandLineArguments3() throws {
        HTTPConfiguration(arguments: CommandLine.arguments + ["--unix-socket", "/tmp/test"])
            .configure(app)

        XCTAssertNotNil(app.http.address)
        XCTAssertEqual(app.http.address, .unixDomainSocket(path: "/tmp/test"))
    }
}
