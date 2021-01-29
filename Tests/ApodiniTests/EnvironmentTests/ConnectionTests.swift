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
    
    func testDefaultConnectionEnvironment() throws {
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)
        
        let endpoint = testHandler.mockEndpoint(app: app)
        let exporter = MockExporter<String>()
        var context = endpoint.createConnectionContext(for: exporter)
        let result = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
            .wait()
        
        // default connection state should be .end
        // thus, we expect a .final(endMessage) here from
        // the TestComponent
        guard case let .final(returnedMessage) = result.typed(String.self) else {
            XCTFail("Expected Response final(\(endMessage)), but was \(result)")
            return
        }
        
        XCTAssertEqual(returnedMessage, endMessage)
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
