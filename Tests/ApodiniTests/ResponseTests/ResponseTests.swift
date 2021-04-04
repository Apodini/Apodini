//
//  ResponseTests.swift
//
//
//  Created by Paul Schmiedmayer on 1/5/21.
//

@testable import Apodini
import ApodiniUtils
import XCTest
import XCTApodini


final class ResponseTests: ApodiniTests {
    struct ResponseHandler: Handler {
        var message: String

        func handle() -> Response<String> {
            .final(message)
        }
    }
    
    struct EmptyResponseHandler: Handler {
        @Environment(\.eventLoopGroup) var eventLoopGroup: EventLoopGroup
        
        func handle() -> EventLoopFuture<Status> {
            eventLoopGroup
                .next()
                .makeSucceededFuture(Void())
                .transform()
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
    
    
    struct TestHandler4: Handler {
        func handle() -> String {
            "Hello Test Handler 4"
        }
    }

    struct ResponseHandler1: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .send("Send")
            default:
                return .final("Final")
            }
        }
    }

    struct ResponseHandler2: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .nothing
            default:
                return .end
            }
        }
    }
    
    func testShouldWrapInFinalByDefault() throws {
        try XCTCheckHandler(
            TestHandler4(),
            application: self.app,
            content: "Hello Test Handler 4"
        )
    }

    func testResponsePassthrough_send() throws {
        try XCTCheckHandler(
            ResponseHandler1(),
            application: self.app,
            connectionState: .open,
            content: "Send",
            connectionEffect: .open
        )
    }

    func testResponsePassthrough_final() throws {
        try XCTCheckHandler(
            ResponseHandler1(),
            application: self.app,
            connectionState: .end,
            content: "Final",
            connectionEffect: .close
        )
    }

    func testResponsePassthrough_nothing() throws {
        try XCTCheckHandler(
            ResponseHandler2(),
            application: self.app,
            connectionState: .open,
            responseType: Empty.self,
            content: nil,
            connectionEffect: .open
        )
    }

    func testResponsePassthrough_end() throws {
        try XCTCheckHandler(
            ResponseHandler2(),
            application: self.app,
            connectionState: .end,
            responseType: Empty.self,
            content: nil,
            connectionEffect: .close
        )
    }
    
    
    func testResponseRequestHandling() throws {
        let expectedContent = "ResponseWithRequest"
        
        try newerXCTCheckHandler(ResponseHandler(message: expectedContent)) {
            MockRequest(expectation: expectedContent)
        }
    }

    func testEventLoopFutureRequestHandling() throws {
        let expectedContent = "ResponseWithRequest"
        
        try newerXCTCheckHandler(FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: expectedContent)) {
            MockRequest(expectation: .response(connectionEffect: .open, expectedContent))
        }
    }
    
    func testEmptyResponseHandler() throws {
        try newerXCTCheckHandler(EmptyResponseHandler()) {
            MockRequest(expectation: .status(.noContent))
        }
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
            .send(["Paul": 42], status: .ok),
            .send(["Paul": 42]),
            .final(["Paul": 42], status: .ok),
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
        
        XCTAssertTrue(typedResponsesFailed.allSatisfy { $0?.content == nil })
        XCTAssertEqual(typedResponsesFailed[0]?.connectionEffect, .open)
        XCTAssertEqual(typedResponsesFailed[0]?.status, nil)
        XCTAssertNil(typedResponsesFailed[1])
        XCTAssertNil(typedResponsesFailed[2])
        XCTAssertNil(typedResponsesFailed[3])
        XCTAssertNil(typedResponsesFailed[4])
        XCTAssertEqual(typedResponsesFailed[5]?.connectionEffect, .close)
        XCTAssertEqual(typedResponsesFailed[5]?.status, nil)
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
