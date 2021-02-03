//
//  ResponseTests.swift
//
//
//  Created by Paul Schmiedmayer on 1/5/21.
//

@testable import Apodini
import NIO
import XCTest
import XCTApodini


final class ResponseTests: ApodiniTests {
    struct ResponseHandler: Handler {
        var message: String

        func handle() -> Response<String> {
            .final(message)
        }
    }
    
    struct FutureBasedHandler: Handler {
        var eventLoop: EventLoop
        var message: String

        func handle() -> EventLoopFuture<EventLoopFuture<EventLoopFuture<Response<String>>>> {
            // Test if `ResponseTransformable` unwraps multiple nested EventLoopFutures
            // Not desirable but its possible:
            eventLoop.makeSucceededFuture(
                eventLoop.makeSucceededFuture(
                    eventLoop.makeSucceededFuture(
                        Apodini.Response.send(message)
                    )
               )
            )
        }
    }
    
    
    func testResponseRequestHandling() throws {
        let expectedContent = "ResponseWithRequest"
        
        let handler = ResponseHandler(message: expectedContent)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            expectedContent: expectedContent,
            connectionEffect: .close
        )
    }

    func testEventLoopFutureRequestHandling() throws {
        let expectedContent = "ResponseWithRequest"
        
        let handler = FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: expectedContent)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            expectedContent: expectedContent,
            connectionEffect: .open
        )
    }
    
    func testResponseMapFunctionality() {
        let responses: [Response<String>] = [.nothing, .send("42"), .final("42"), .end]
        
        let intResponses = responses.map { response in
            response.map { Int($0) }
        }
        XCTAssertEqual(intResponses[0].content, nil)
        XCTAssertEqual(intResponses[1].content, 42)
        XCTAssertEqual(intResponses[2].content, 42)
        XCTAssertEqual(intResponses[3].content, nil)
    }
    
    func testResponseGeneration() throws {
        try ["Paul": 42]
            .transformToResponse(on: app.eventLoopGroup.next())
            .map { response in
                let transformedResponse = response.typeErasured.typed([String: Int].self)
                XCTAssertEqual(transformedResponse?.content, ["Paul": 42])
            }
            .wait()
    }
    
    func testResponseTypeErasureFunctionality() {
        let responses: [Response<[String: Int]>] = [
            .nothing,
            .send(["Paul": 42]),
            .final(["Paul": 42]),
            .end
        ]
        
        let typeErasuredResponses = responses.map { response in
            response.typeErasured
        }
        typeErasuredResponses.forEach { typeErasuredResponse in
            XCTAssert(type(of: typeErasuredResponse).self == Response<AnyEncodable>.self)
        }
        
        // Make sure that type erasing a already type erasured Response doesn't have any effect
        let doubbleTypeErasuredResponses = typeErasuredResponses.map { response in
            response.typeErasured
        }
        doubbleTypeErasuredResponses.forEach { typeErasuredResponse in
            XCTAssert(type(of: typeErasuredResponse).self == Response<AnyEncodable>.self)
        }
        
        let typedResponses = typeErasuredResponses.map { typedResponse in
            typedResponse.typed([String: Int].self)
        }
        zip(responses, typedResponses).forEach { response, typedResponse in
            XCTAssertEqual(response.content, typedResponse?.content)
        }
        
        let typedResponsesFailed = typeErasuredResponses.map { typedResponse in
            typedResponse.typed(Int.self)
        }
        XCTAssert(typedResponsesFailed[0] != nil)
        XCTAssertEqual(typedResponsesFailed[0]?.connectionEffect, .open)
        XCTAssert(typedResponsesFailed[1] == nil)
        XCTAssert(typedResponsesFailed[2] == nil)
        XCTAssert(typedResponsesFailed[3] != nil)
        XCTAssertEqual(typedResponsesFailed[0]?.connectionEffect, .close)
    }
    
    func testAnyEncodable() {
        let single = AnyEncodable(42)
        let double = AnyEncodable(AnyEncodable(42))
        let triple = AnyEncodable(AnyEncodable(AnyEncodable(42)))
        
        XCTAssertEqual(single.typed(Int.self), 42)
        XCTAssertEqual(double.typed(Int.self), 42)
        XCTAssertEqual(triple.typed(Int.self), 42)
    }
}
