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
    struct AddBirdsComponent: EndpointNode {
        @_Database
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

    class JSONSemanticModelBuilder: SemanticModelBuilder {
        override func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
            guard let byteBuffer = request.body.data,
                  let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
            }

            return try JSONDecoder().decode(type, from: data)
        }
    }
    
    
    func testComponentCreation() throws {
        let bird = Bird(name: "Hummingbird", age: 2)
        let birdData = ByteBuffer(data: try JSONEncoder().encode(bird))
        
        let request = Request(application: app, collectedBody: birdData, on: app.eventLoopGroup.next())
        
        let response = try request
            .enterRequestContext(with: AddBirdsComponent(), using: JSONSemanticModelBuilder(app)) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        let responseData = try XCTUnwrap(response.body.data)
        let responseBirds = try JSONDecoder().decode([Bird].self, from: responseData)
        XCTAssert(responseBirds.count == 3)
        XCTAssert(responseBirds[2] == bird)
    }
}
