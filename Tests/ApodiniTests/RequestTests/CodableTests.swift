//
//  CodableTests.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

import XCTest
import NIO
@testable import Apodini

final class CodableTests: ApodiniTests, EncodableContainerVisitor {
    struct ActionHandler: Handler {
        var message: String

        func handle() -> Action<String> {
            .final(message)
        }
    }

    struct FutureBasedHandler: Handler {
        var eventLoop: EventLoop
        var message: String

        func handle() -> Action<EventLoopFuture<EventLoopFuture<EventLoopFuture<String>>>> {
            // this tests if the `EventLoopFutureUnwrapper` properly unwraps multiple nested EventLoopFutures
            // I hope no one would ever do that, but its possible, thus we need to handle it properly
            .send(
                eventLoop.makeSucceededFuture(
                    eventLoop.makeSucceededFuture(
                        eventLoop.makeSucceededFuture(
                            message
                        )
                   )
                )
            )
        }
    }

    static var expectedValue: String = ""

    override func setUpWithError() throws {
        try super.setUpWithError()
        CodableTests.expectedValue = ""
    }

    func visit<Value: Encodable>(_ action: Action<Value>) {
        switch action {
        case let .final(element):
            // swiftlint:disable:next force_cast
            XCTAssertEqual(element as! String, CodableTests.expectedValue)
        default:
            XCTFail("Expected value wrapped in .final")
        }
    }

    func callVisitor<H: Handler>(_ handler: H) {
        let result = handler.handle()
        switch result {
        case let apodiniEncodable as EncodableContainer:
            apodiniEncodable.accept(self)
        default:
            XCTFail("Expected ApodiniEncodable")
        }
    }

    func testShouldCallAction() {
        CodableTests.expectedValue = "Action"
        callVisitor(ActionHandler(message: CodableTests.expectedValue))
    }

    func testActionRequestHandling() throws {
        CodableTests.expectedValue = "ActionWithRequest"
        let handler = ActionHandler(message: CodableTests.expectedValue)
        let modifier = EmojiMediator(emojis: "-")
        let endpoint = handler.mockEndpoint(responseTransformers: [ { modifier } ])

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
            .wait()

        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.final")
            return
        }
        let stringResult: String = try XCTUnwrap(responseValue.value as? String)
        XCTAssertEqual(stringResult, "- " + CodableTests.expectedValue + " -")
    }

    func testEventLoopFutureFlattening() throws {
        CodableTests.expectedValue = "ActionWithRequest"
        let handler = FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: CodableTests.expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()

        guard case let .send(responseValue) = result else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.send")
            return
        }
        let stringResult: String = try XCTUnwrap(responseValue.value as? String)
        XCTAssertEqual(stringResult, CodableTests.expectedValue)
    }
}
