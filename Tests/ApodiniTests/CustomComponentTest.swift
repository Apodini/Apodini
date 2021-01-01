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

final class CustomComponentTests: ApodiniTests {
    struct AddBirdsHandler: Handler {
        @Apodini.Environment(\.database)
        var database: Fluent.Database

        @Parameter
        var bird: Bird


        func handle() -> EventLoopFuture<[Bird]> {
            bird.save(on: database)
                .flatMap { _ in
                    Bird.query(on: database)
                        .all()
                }
        }
    }

    func testComponentCreation() throws {
        let addBird = AddBirdsHandler()
        let endpoint = addBird.mockEndpoint()

        let bird = Bird(name: "Hummingbird", age: 2)
        let exporter = MockExporter<String>(queued: bird)

        let requestHandler = endpoint.createRequestHandler(for: exporter)

        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
            .wait()
        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }

        let responseBirds: [Bird] = try XCTUnwrap(responseValue.value as? [Bird])

        XCTAssert(responseBirds.count == 3)
        XCTAssert(responseBirds[2] == bird)
    }
}
