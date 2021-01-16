//
//  ApodiniTests.swift
//  
//
//  Created by Paul Schmiedmayer on 7/7/20.
//

import XCTest
import FluentSQLiteDriver
@testable import Apodini
@testable import ApodiniDatabase

class ApodiniTests: XCTestCase {
    // Vapor Application
    // swiftlint:disable implicitly_unwrapped_optional
    var app: Application!
    // Model Objects
    var bird1 = Bird(name: "Swift", age: 5)
    var bird2 = Bird(name: "Corvus", age: 1)


    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application()

        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        EnvironmentValues.shared.database = try database()
        
        app.migrations.add(
            CreateBird(),
            DeviceMigration()
        )
        
        
        try app.autoMigrate().wait()
        
        try bird1.create(on: database()).wait()
        try bird2.create(on: database()).wait()
    }

    func database() throws -> Database {
        try XCTUnwrap(self.app.db)
    }
}
