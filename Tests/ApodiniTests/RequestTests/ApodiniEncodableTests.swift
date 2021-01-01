//
//  ApodiniEncodableTests.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

import XCTest
import NIO
@testable import Apodini

final class ApodiniEncodableTests: ApodiniTests, EncodableContainerVisitor {
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
        ApodiniEncodableTests.expectedValue = ""
    }

    func visit<Value: Encodable>(_ action: Action<Value>) {
        switch action {
        case let .final(element):
            // swiftlint:disable:next force_cast
            XCTAssertEqual(element as! String, ApodiniEncodableTests.expectedValue)
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
        ApodiniEncodableTests.expectedValue = "Action"
        callVisitor(ActionHandler(message: ApodiniEncodableTests.expectedValue))
    }

    func testActionRequestHandling() throws {
        ApodiniEncodableTests.expectedValue = "ActionWithRequest"
        let handler = ActionHandler(message: ApodiniEncodableTests.expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
            .wait()

        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.final")
            return
        }
        let stringResult: String = try XCTUnwrap(responseValue.value as? String)
        XCTAssertEqual(stringResult, ApodiniEncodableTests.expectedValue)
    }

    func testEventLoopFutureRequestHandling() throws {
        ApodiniEncodableTests.expectedValue = "ActionWithRequest"
        let handler = FutureBasedHandler(eventLoop: app.eventLoopGroup.next(), message: ApodiniEncodableTests.expectedValue)
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>()

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()

        guard case let .send(responseValue) = result else {
            XCTFail("Expected return value of ActionHandler to be wrapped in Action.send")
            return
        }
        print("Found value \(responseValue.value)")
        let stringResult: String = try XCTUnwrap(responseValue.value as? String)
        XCTAssertEqual(stringResult, ApodiniEncodableTests.expectedValue)
    }
}
