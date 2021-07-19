//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniDatabase
import XCTest
@testable import ApodiniNotifications

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
            .addNotifications()
            .configure(self.app)
        XCTAssertNotNil(app.databases.configuration())
    }
    
    func testDatabaseRevert() throws {
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "DatabaseSchemaTest"),
            isDefault: true
        )
        app.migrations.add(DeviceMigration())
        try app.autoMigrate().wait()
        XCTAssertNoThrow(try app.autoRevert().wait())
    }
}
