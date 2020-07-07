//
//  ApodiniTests.swift
//  
//
//  Created by Paul Schmiedmayer on 7/7/20.
//

import XCTVapor
import FluentSQLiteDriver

class ApodiniTests: XCTestCase {
    // Vapor Application
    var app: Vapor.Application!
    // Model Objects
    var bird1 = Bird(name: "Swift", age: 5)
    var bird2 = Bird(name: "Corvus", age: 1)
    var birdId1: UUID!
    var birdId2: UUID!
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = Application(.testing)
        
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "ApodiniTest"),
            isDefault: true
        )
        
        app.migrations.add(
            CreateBird()
        )
        
        try app.autoMigrate().wait()
        
        
        try bird1.create(on: database()).wait()
        try bird2.create(on: database()).wait()
        birdId1 = try XCTUnwrap(bird1.id)
        birdId2 = try XCTUnwrap(bird2.id)
    }
    
    override func tearDownWithError() throws {
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }
    
    
    func tester() throws -> XCTApplicationTester {
        try XCTUnwrap(app.testable())
    }
    
    func database() throws -> Database {
        try XCTUnwrap(self.app.db)
    }
}
