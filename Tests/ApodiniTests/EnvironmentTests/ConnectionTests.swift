//
//  ConnectionTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

import XCTest
@testable import Apodini

final class ConnectionTests: ApodiniTests {
    let endMessage = "End"
    let openMessage = "Open"

    struct TestHandler: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection

        var endMessage: String
        var openMessage: String

        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .send(openMessage)
            case .end:
                return .final(endMessage)
            }
        }
    }

    func testDefaultConnectionEnvironment() {
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)

        let returnedAction = testHandler.handle()
        // default connection state should be .end
        // thus, we expect a .final(endMessage) here from
        // the TestComponent
        if case let .final(returnedMessage) = returnedAction {
            XCTAssertEqual(returnedMessage, endMessage)
        } else {
            XCTFail("Expected Response final(\(endMessage)), but was \(returnedAction)")
        }
    }

    func testConnectionInjection() {
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)
        
        var connection = Connection(state: .open)
        connection.enterConnectionContext(with: testHandler) { handler in
            let returnedActionWithOpen = handler.handle()
            if case let .send(returnedMessageWithOpen) = returnedActionWithOpen {
                XCTAssertEqual(returnedMessageWithOpen, openMessage)
            } else {
                XCTFail("Expected Response send(\(openMessage)), but was \(returnedActionWithOpen)")
            }
        }

        connection.state = .end
        connection.enterConnectionContext(with: testHandler) { handler in
            let returnedActionWithEnd = handler.handle()
            if case let .final(returnedMessageWithEnd) = returnedActionWithEnd {
                XCTAssertEqual(returnedMessageWithEnd, endMessage)
            } else {
                XCTFail("Expected Response final(\(endMessage)), but was \(returnedActionWithEnd)")
            }
        }
    }
}
