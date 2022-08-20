//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import FluentSQLiteDriver
import Apodini
import XCTest
import ApodiniDatabase
import ApodiniUtils
@testable import ApodiniAudit

open class XCTApodiniTest: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    open var app: Application!
    
    static var didInstallNLTK = false
    
    override open class func setUp() {
        if !didInstallNLTK {
            // Run the AuditSetupCommand. It doesn't matter which WebService we specify.
            let app = Application()
            let commandType = AuditSetupNLTKCommand<EmptyWebService>.self
            let command = commandType.init()
            do {
                try command.run(app: app)
                print("Installed requirements!")
            } catch {
                fatalError("Could not install NLTK and and corpora!")
            }
        }
        didInstallNLTK = true
    }
    
    override open func setUpWithError() throws {
        try super.setUpWithError()
        app = Application()
    }
    
    override open func tearDownWithError() throws {
        try super.tearDownWithError()
        app.shutdown()
        XCTAssertApodiniApplicationNotRunning()
    }
    
    
    open func database() throws -> Database {
        try XCTUnwrap(self.app.database)
    }
    
    open func addMigrations(_ migrations: Migration...) throws {
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        app.migrations.add(migrations)
        
        try app.autoMigrate().wait()
    }
}

struct EmptyWebService: WebService {
    var content: some Component {
        MyEmptyHandler()
    }
}

struct MyEmptyHandler: Handler {
    func handle() -> String {
        ""
    }
}
