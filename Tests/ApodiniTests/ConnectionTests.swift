//
//  ConnectionTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

import XCTest
import Vapor
@testable import Apodini

final class ConnectionTests: XCTestCase {
    struct TestComponent: Component {
        @Apodini.Environment(\.connection)
        var connection: Connection

        var endMessage: String
        var openMessage: String

        func handle() -> Action<String> {
            switch connection.state {
            case .open:
                return .send(openMessage)
            case .end:
                return .final(endMessage)
            }
        }
    }

    func testConnectionInjection() {
        let endMessage = "End"
        let openMessage = "Open"

        let testComponent = TestComponent(endMessage: endMessage, openMessage: openMessage)

        var connection = Connection(state: .open)
        let returnedActionWithOpen = testComponent.withEnvironment(connection, for: \.connection).handle()
        if case let .send(returnedMessageWithOpen) = returnedActionWithOpen {
            XCTAssertEqual(returnedMessageWithOpen, openMessage)
        } else {
            XCTFail("Expected Action send(\(openMessage)), but was \(returnedActionWithOpen)")
        }

        connection.state = .end
        let returnedActionWithEnd = testComponent.withEnvironment(connection, for: \.connection).handle()
        if case let .final(returnedMessageWithEnd) = returnedActionWithEnd {
            XCTAssertEqual(returnedMessageWithEnd, endMessage)
        } else {
            XCTFail("Expected Action final(\(openMessage)), but was \(returnedActionWithEnd)")
        }
    }
}
