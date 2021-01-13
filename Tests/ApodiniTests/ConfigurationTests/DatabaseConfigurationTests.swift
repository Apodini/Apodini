//
//  DatabaseConfigurationTests.swift
//  
//
//  Created by Tim Gymnich on 13.1.21.
//

@testable import Apodini
import XCTest

final class DatabaseConfigurationTests: XCTestCase {
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
        DatabaseConfiguration(.sqlite(.memory))
            .addNotifications()
            .configure(self.app)
        XCTAssertNotNil(app.databases.configuration())
    }

}
