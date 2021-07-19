//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniDatabase
import XCTest

final class DatabaseConfigurationTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    var app: Application!

    override func setUp() {
        super.setUp()
        self.app = Application()
    }

    override func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testDatabaseSetup() throws {
        DatabaseConfiguration(.sqlite(.memory), as: .sqlite)
            .configure(self.app)
        XCTAssertNotNil(app.databases.configuration())
    }
}
