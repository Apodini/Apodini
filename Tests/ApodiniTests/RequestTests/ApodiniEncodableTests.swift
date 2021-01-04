//
//  ApodiniEncodableTests.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

@testable import Apodini
import NIO
import XCTest


final class ActionTests: ApodiniTests {
    struct ActionHandler: Handler {
        var message: String

        func handle() -> Action<String> {
            .final(message)
        }
    }
    
    struct FutureBasedHandler: Handler {
        var eventLoop: EventLoop
        var message: String

        func handle() -> EventLoopFuture<EventLoopFuture<EventLoopFuture<Action<String>>>> {
            // this tests if the `EventLoopFutureUnwrapper` properly unwraps multiple nested EventLoopFutures
            // I hope no one would ever do that, but its possible, thus we need to handle it properly
            eventLoop.makeSucceededFuture(
                eventLoop.makeSucceededFuture(
                    eventLoop.makeSucceededFuture(
                        Action.send(message)
                    )
               )
            )
        }
    }
    
    
    func testActionRequestHandling() throws {
        let expectedValue = "ActionWithRequest"
        
        let handler = ActionHandler(message: expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
            .wait()

        guard case let .final(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.final")
            return
        }
        
        XCTAssertEqual(responseValue, expectedValue)
    }

    func testEventLoopFutureRequestHandling() throws {
        let expectedValue = "ActionWithRequest"
        
        let handler = FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()

        guard case let .send(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.send")
            return
        }
       
        XCTAssertEqual(responseValue, expectedValue)
    }
}
