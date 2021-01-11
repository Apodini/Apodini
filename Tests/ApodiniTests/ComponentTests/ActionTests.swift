//
//  ActionTests.swift
//
//
//  Created by Paul Schmiedmayer on 1/5/21.
//

@testable import Apodini
import NIO
import XCTest


final class ActionTests: ApodiniTests {
    struct ActionHandler: Handler {
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
    
    
    func testActionRequestHandling() throws {
        let expectedValue = "ActionWithRequest"
        
        let handler = ActionHandler(message: expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()
        var context = endpoint.createConnectionContext(for: exporter)
        
        let result = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()

        guard case let .final(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Response.final")
            return
        }
        
        XCTAssertEqual(responseValue, expectedValue)
    }

    func testEventLoopFutureRequestHandling() throws {
        let expectedValue = "ActionWithRequest"
        
        let handler = FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        var context = endpoint.createConnectionContext(for: exporter)
        
        let result = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()

        guard case let .send(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Response.send")
            return
        }
       
        XCTAssertEqual(responseValue, expectedValue)
    }
    
    func testActionMapFunctionality() {
        let actions: [Response<String>] = [.nothing, .send("42"), .final("42"), .end]
        
        let intActions = actions.map { action in
            action.map { Int($0) }
        }
        XCTAssertEqual(intActions[0].element, nil)
        XCTAssertEqual(intActions[1].element, 42)
        XCTAssertEqual(intActions[2].element, 42)
        XCTAssertEqual(intActions[3].element, nil)
    }
    
    func testActionGeneration() throws {
        try ["Paul": 42]
            .transformToResponse(on: app.eventLoopGroup.next())
            .map { action in
                let transformedAction = action.typeErasured.typed([String: Int].self)
                XCTAssertEqual(transformedAction?.element, ["Paul": 42])
            }
            .wait()
    }
    
    func testActionTypeErasureFunctionality() {
        let actions: [Response<[String: Int]>] = [
            .nothing,
            .send(["Paul": 42]),
            .final(["Paul": 42]),
            .end
        ]
        
        let typeErasuredActions = actions.map { action in
            action.typeErasured
        }
        typeErasuredActions.forEach { typeErasuredAction in
            XCTAssert(type(of: typeErasuredAction).self == Response<AnyEncodable>.self)
        }
        
        // Make sure that type erasing a already type erasured Response doesn't have any effect
        let doubbleTypeErasuredActions = typeErasuredActions.map { action in
            action.typeErasured
        }
        doubbleTypeErasuredActions.forEach { typeErasuredAction in
            XCTAssert(type(of: typeErasuredAction).self == Response<AnyEncodable>.self)
        }
        
        let typedActions = typeErasuredActions.map { typedAction in
            typedAction.typed([String: Int].self)
        }
        zip(actions, typedActions).forEach { action, typedAction in
            XCTAssertEqual(action.element, typedAction?.element)
        }
        
        let typedActionsFailed = typeErasuredActions.map { typedAction in
            typedAction.typed(Int.self)
        }
        XCTAssert(typedActionsFailed[0] != nil)
        guard case .nothing = typedActionsFailed[0] else {
            XCTFail("typedActionsFailed[0] must be .nothing as the type mapping shouldn't be affected by the mismatch in types")
            return
        }
        XCTAssert(typedActionsFailed[1] == nil)
        XCTAssert(typedActionsFailed[2] == nil)
        guard case .end = typedActionsFailed[3] else {
            XCTFail("typedActionsFailed[0] must be .end as the type mapping shouldn't be affected by the mismatch in types")
            return
        }
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
