//
//  CustomCompoentTest.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


final class CustomComponentTests: XCTestCase {
    final class Bird: Model, Content {
        static var schema: String = "Birds"
        
        @ID
        var id: UUID?
        @Field(key: "name")
        var name: String
        @Field(key: "age")
        var age: Int
        
        
        init(name: String, age: Int) {
            self.id = nil
            self.name = name
            self.age = age
        }
        
        init() {}
    }

    struct AddBirdsComponent: Component {
        @CurrentDatabase
        var database: Fluent.Database
        
        @Body
        var bird: Bird
        
        
        func handle(_ request: Vapor.Request) -> EventLoopFuture<[CustomComponentTests.Bird]> {
            Bird.query(on: database)
                .all()
                .flatMap { _ in
                    Bird.query(on: database)
                        .all()
                }
        }
    }
    
    var app: Application!
    
    
    override func setUp() {
        app = Application(.testing)
    }
    
    override func tearDown() {
        app.shutdown()
    }
}
