//
//  CustomComponentTest.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


// Test commented out until Handlers can return EventLoopFutures
//final class CustomComponentTests: ApodiniTests {
//    struct AddBirdsHandler: Handler {
//        @_Database
//        var database: Fluent.Database
//
//        @Parameter
//        var bird: Bird
//
//
//        func handle() -> EventLoopFuture<[Bird]> {
//            bird.save(on: database)
//                .flatMap { _ in
//                    Bird.query(on: database)
//                        .all()
//                }
//        }
//    }
//
//    func testComponentCreation() throws {
//        let addBird = AddBirdsHandler()
//        let bird = Bird(name: "Hummingbird", age: 2)
//
//        let request = MockRequest.createRequest(on: addBird, running: app.eventLoopGroup.next(), database: self.app.db, queuedParameters: bird)
//
//        let responseBirds = try request
//            .enterRequestContext(with: addBird) { component in
//                component.handle()
//            }
//            .wait()
//
//        XCTAssert(responseBirds.count == 3)
//        XCTAssert(responseBirds[2] == bird)
//    }
//}
